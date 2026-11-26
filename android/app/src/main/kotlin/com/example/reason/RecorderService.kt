package com.example.reason

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.view.Display
import android.view.Surface
import androidx.camera.core.Preview
import androidx.camera.video.VideoRecordEvent
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import java.io.File
import java.util.concurrent.Executors

@SuppressLint("InlinedApi") // ServiceCompat ignores the type below API 29.
class RecorderService : LifecycleService() {
    companion object {
        @Volatile
        var instance: RecorderService? = null
            internal set

        const val ACTION_START_PREVIEW =
            "com.example.reason.action.START_PREVIEW"
        const val ACTION_START_RECORDING =
            "com.example.reason.action.START_RECORDING"
        const val ACTION_STOP_RECORDING =
            "com.example.reason.action.STOP_RECORDING"
        const val ACTION_STOP_SERVICE =
            "com.example.reason.action.STOP_SERVICE"
        const val ACTION_NOTIFICATION_STOP =
            "com.example.reason.action.NOTIFICATION_STOP"

        const val EXTRA_CAMERA = "camera"
        const val EXTRA_RESOLUTION = "resolution"
        const val EXTRA_SEGMENT_MINUTES = "segmentMinutes"
        const val EXTRA_BUDGET_BYTES = "budgetBytes"
        const val EXTRA_SENSITIVITY = "sensitivity"
        const val EXTRA_DATA_SAVER = "dataSaver"
        const val EXTRA_DESTROY_AFTER_MINUTES = "destroyAfterMinutes"
        const val EXTRA_AUDIO = "audio"
        const val EXTRA_STAMP = "stamp"
        const val EXTRA_ZONE = "zone"
        const val EXTRA_VISIBLE = "activityVisible"
        const val EXTRA_AUTO = "auto"

        val RESOLUTION_VALUES = setOf("1440p", "1080p", "720p", "480p")

        private const val CHANNEL_ID = "reason.recording"
        private const val NOTIFICATION_ID = 1
        const val AUTO_NOTIFICATION_ID = 2
        private const val LOW_SPACE_BYTES = 500L * 1024L * 1024L
        private const val TICK_MS = 1_000L
        private const val SPACE_CHECK_TICKS = 5
        private const val STOP_TIMEOUT_MS = 5_000L
        private const val WAKE_LOCK_TIMEOUT_MS = 12L * 60L * 60L * 1000L
        private const val CAMERA_RETRY_MS = 2_000L
        private const val CAMERA_RETRIES = 30
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private lateinit var session: CameraSession

    @Volatile
    private var repos: RepoSet? = null
    private var usedBytesCache = 0L

    private var state = "idle"
    private var recordingRequested = false
    private var stopRequested = false
    private var stopServiceWhenFinalized = false
    private var activityVisible = false
    private var cameraRetries = 0

    /** True when recording was started by the car detector, not by a tap. */
    @Volatile
    var autoStarted = false
        private set

    private var camera = "rear"
    private var resolution = "1080p"
    private var segmentMinutes = 3
    private var budgetBytes = StatusBus.DEFAULT_BUDGET_BYTES
    private var sensitivity = "normal"
    private var dataSaver = false
    private var audio = false
    private var stamp = false
    private var zone: String? = null
    private var destroyAfterMinutes = 0
    private var segmentMs = 3 * 60_000L
    private var nextSegmentIndex = 0
    private var sessionStartElapsed = 0L
    private var currentPart: File? = null
    private var sensorManager: SensorManager? = null
    private var crashDetector: CrashDetector? = null

    private var warning: String? = null
    private var lastError: String? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var tickerRunning = false
    private var spaceTickCounter = 0

    private val ticker = object : Runnable {
        override fun run() {
            if (!tickerRunning) return
            emitStatus()
            if (++spaceTickCounter >= SPACE_CHECK_TICKS) {
                spaceTickCounter = 0
                checkFreeSpace()
            }
            if (tickerRunning) mainHandler.postDelayed(this, TICK_MS)
        }
    }

    private val stopWatchdog = Runnable {
        if (recordingRequested && stopRequested) {
            lastError = "Recording did not finalize in time"
            // Without this the next start cannot begin a segment.
            if (::session.isInitialized) session.abortRecording()
            finishSession()
        }
    }

    private val cameraRetry = Runnable {
        if (!recordingRequested || stopRequested) return@Runnable
        state = "starting"
        emitStatus()
        session.forceRebind(config(), displayRotation())
    }

    private val accelerationListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val detector = crashDetector ?: return
            if (event.values.size < 3) return
            val locked = detector.onSample(
                event.values[0],
                event.values[1],
                event.values[2],
                SystemClock.elapsedRealtime(),
            )
            if (!locked) return
            currentPart?.let { ClipStore.protectPart(it) }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
    }

    val isRecordingSession: Boolean
        get() = recordingRequested

    override fun onCreate() {
        super.onCreate()
        instance = this
        createChannel()
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA,
            )
        } catch (error: Exception) {
            lastError = error.message
            stopSelf()
            return
        }

        session = CameraSession(
            this,
            this,
            ContextCompat.getMainExecutor(this),
            object : CameraSession.Listener {
                override fun onCameraReady() = handleCameraReady()

                override fun onCameraError(message: String) =
                    handleCameraError(message)

                override fun onSegmentFinalized(
                    part: File,
                    errorCode: Int,
                    hasError: Boolean,
                ) = handleFinalize(part, errorCode, hasError)
            },
        )

        ClipStore.clipDir(this)?.let { dir ->
            dir.mkdirs()
            ClipStore.cleanupInterrupted(dir)
            warning = ClipStore.readWarning(dir)
        }
    }

    override fun onBind(intent: Intent): IBinder? {
        super.onBind(intent)
        return null
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {
        super.onStartCommand(intent, flags, startId)
        if (!::session.isInitialized) {
            // onCreate failed to reach the foreground: nothing can record.
            stopSelf(startId)
            return START_NOT_STICKY
        }
        when (intent?.action) {
            null -> stopSelf()
            ACTION_START_PREVIEW -> handleStartPreview(intent)
            ACTION_START_RECORDING -> handleStartRecording(intent)
            ACTION_STOP_RECORDING -> handleStopRecording()
            ACTION_STOP_SERVICE, ACTION_NOTIFICATION_STOP -> handleStopService()
            else -> stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (!recordingRequested) stopSelf()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        io.shutdown()
        tickerRunning = false
        releaseWakeLock()
        stopCrashDetection()
        if (::session.isInitialized) session.release()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        if (instance === this) {
            instance = null
            StatusBus.emit(StatusBus.idleStatus(this))
        }
        super.onDestroy()
    }

    fun setActivityVisible(visible: Boolean) {
        activityVisible = visible
        if (!visible && !recordingRequested) stopSelf()
    }

    fun setPreviewRotation(rotation: Int) {
        if (::session.isInitialized) session.setPreviewRotation(rotation)
    }

    fun attachPreview(provider: Preview.SurfaceProvider?) {
        if (::session.isInitialized) session.attachPreview(provider)
    }

    fun detachPreview(provider: Preview.SurfaceProvider) {
        if (::session.isInitialized) session.detachPreview(provider)
    }

    fun statusMap(): Map<String, Any?> {
        val dir = ClipStore.clipDir(this)
        val used = usedBytesCache + (currentPart?.length() ?: 0L)
        val free = dir?.let { ClipStore.freeBytes(it) } ?: 0L
        val elapsed = if (recordingRequested) {
            (SystemClock.elapsedRealtime() - sessionStartElapsed)
                .coerceAtLeast(0L)
        } else {
            0L
        }
        return mapOf(
            "state" to state,
            "camera" to camera,
            "resolution" to resolution,
            "segmentMinutes" to segmentMinutes,
            "budgetBytes" to budgetBytes,
            "sessionElapsedMs" to elapsed,
            "segmentIndex" to nextSegmentIndex,
            "usedBytes" to used,
            "freeBytes" to free,
            "recording" to recordingRequested,
            "warning" to warning,
            "lastError" to lastError,
        )
    }

    private fun handleStartPreview(intent: Intent) {
        if (recordingRequested) return
        camera = if (intent.getStringExtra(EXTRA_CAMERA) == "front") {
            "front"
        } else {
            "rear"
        }
        resolution = resolutionFor(intent)
        lastError = null
        // A warning explains an old stop; a fresh preview is not that stop.
        clearWarning()
        activityVisible = intent.getBooleanExtra(EXTRA_VISIBLE, activityVisible)
        state = "starting"
        updateNotification()
        emitStatus()
        session.ensureBound(config(), displayRotation())
    }

    private fun handleStartRecording(intent: Intent) {
        if (recordingRequested) return
        val dir = ClipStore.clipDir(this)
        if (dir == null) {
            failRecording("storage_error", "Clips directory unavailable")
            return
        }
        dir.mkdirs()
        // Built on the io thread: a picked folder is a ContentProvider query.
        repos = null
        usedBytesCache = 0L
        refreshUsage()

        camera = if (intent.getStringExtra(EXTRA_CAMERA) == "front") {
            "front"
        } else {
            "rear"
        }
        activityVisible = intent.getBooleanExtra(EXTRA_VISIBLE, activityVisible)
        resolution = resolutionFor(intent)
        segmentMinutes = intent.getIntExtra(EXTRA_SEGMENT_MINUTES, 3)
            .takeIf { it in 1..60 } ?: 3
        budgetBytes = intent.getLongExtra(
            EXTRA_BUDGET_BYTES,
            StatusBus.DEFAULT_BUDGET_BYTES,
        ).takeIf { it > 0 } ?: StatusBus.DEFAULT_BUDGET_BYTES
        sensitivity = intent.getStringExtra(EXTRA_SENSITIVITY) ?: "normal"
        dataSaver = intent.getBooleanExtra(EXTRA_DATA_SAVER, false)
        audio = intent.getBooleanExtra(EXTRA_AUDIO, false)
        stamp = intent.getBooleanExtra(EXTRA_STAMP, false)
        zone = intent.getStringExtra(EXTRA_ZONE)
        destroyAfterMinutes = intent.getIntExtra(
            EXTRA_DESTROY_AFTER_MINUTES,
            0,
        ).coerceAtLeast(0)
        segmentMs = segmentMinutes * 60_000L
        cameraRetries = 0

        val free = ClipStore.freeBytes(dir)
        if (free == null) {
            failRecording("storage_error", "Cannot read free space")
            return
        }
        if (free < LOW_SPACE_BYTES) {
            setWarning("low_storage", "Less than 500 MB free")
            clearAutoNotification()
            state = if (session.isBound) "previewing" else "idle"
            updateNotification()
            emitStatus()
            return
        }

        clearWarning()
        lastError = null
        recordingRequested = true
        autoStarted = intent.getBooleanExtra(EXTRA_AUTO, false)
        stopRequested = false
        stopServiceWhenFinalized = false
        sessionStartElapsed = SystemClock.elapsedRealtime()
        nextSegmentIndex = 0
        currentPart = null
        acquireWakeLock()
        startTicker()
        startCrashDetection()

        if (session.isBound && session.config == config()) {
            startNextSegment()
        } else {
            state = "starting"
            updateNotification()
            emitStatus()
            session.ensureBound(config(), displayRotation())
        }
    }

    private fun handleStopRecording() {
        if (!recordingRequested) return
        stopRequested = true
        state = "stopping"
        if (session.isRecording) {
            session.stopSegment()
            mainHandler.postDelayed(stopWatchdog, STOP_TIMEOUT_MS)
            updateNotification()
            emitStatus()
        } else {
            finishSession()
        }
    }

    private fun handleStopService() {
        if (recordingRequested) {
            stopRequested = true
            stopServiceWhenFinalized = true
            state = "stopping"
            if (session.isRecording) {
                session.stopSegment()
                mainHandler.postDelayed(stopWatchdog, STOP_TIMEOUT_MS)
                updateNotification()
                emitStatus()
            } else {
                finishSession()
            }
        } else {
            stopSelf()
        }
    }

    private fun handleCameraReady() {
        if (recordingRequested) {
            if (!session.isRecording && currentPart == null) startNextSegment()
            return
        }
        state = "previewing"
        updateNotification()
        emitStatus()
    }

    private fun handleCameraError(message: String) {
        if (recordingRequested && !stopRequested) {
            scheduleCameraRetry(message)
            return
        }
        setWarning("camera_error", message)
        recordingRequested = false
        stopRequested = false
        releaseWakeLock()
        stopTicker()
        stopCrashDetection()
        state = if (session.isBound) "previewing" else "idle"
        updateNotification()
        emitStatus()
        if (!activityVisible) stopSelf()
    }

    /** Another app took the camera: rebind a few times before giving up. */
    private fun scheduleCameraRetry(message: String) {
        if (cameraRetries >= CAMERA_RETRIES) {
            setWarning("camera_error", message)
            finishSession()
            return
        }
        cameraRetries++
        lastError = message
        state = "starting"
        updateNotification()
        emitStatus()
        mainHandler.removeCallbacks(cameraRetry)
        mainHandler.postDelayed(cameraRetry, CAMERA_RETRY_MS)
    }

    private fun startNextSegment() {
        if (!recordingRequested || stopRequested) return
        val dir = ClipStore.clipDir(this)
        if (dir == null) {
            failRecording("storage_error", "Clips directory unavailable")
            return
        }
        val free = ClipStore.freeBytes(dir)
        if (free == null) {
            failRecording("storage_error", "Cannot read free space")
            return
        }
        if (free < LOW_SPACE_BYTES) {
            stopWithWarning("low_storage", "Less than 500 MB free")
            return
        }

        val limit = SegmentPlan.nextLimitMs(
            SystemClock.elapsedRealtime(),
            sessionStartElapsed,
            nextSegmentIndex,
            segmentMs,
        )
        val part = ClipStore.partFile(dir, System.currentTimeMillis())
        currentPart = part
        nextSegmentIndex++
        if (!session.startSegment(part, limit, displayRotation())) {
            currentPart = null
            scheduleCameraRetry("Could not start the encoder")
            return
        }
        if (warning != null) clearWarning()
        cameraRetries = 0
        state = "recording"
        updateNotification()
        emitStatus()
    }

    private fun handleFinalize(
        part: File,
        errorCode: Int,
        hasError: Boolean,
    ) {
        mainHandler.removeCallbacks(stopWatchdog)
        currentPart = null

        val usable = errorCode == VideoRecordEvent.Finalize.ERROR_NONE ||
            errorCode == VideoRecordEvent.Finalize.ERROR_DURATION_LIMIT_REACHED ||
            errorCode == VideoRecordEvent.Finalize.ERROR_FILE_SIZE_LIMIT_REACHED ||
            errorCode == VideoRecordEvent.Finalize.ERROR_INSUFFICIENT_STORAGE ||
            errorCode == VideoRecordEvent.Finalize.ERROR_SOURCE_INACTIVE
        val hasData = usable && part.exists() && part.length() > 0

        if (hasData) {
            ClipStore.finalizePart(part)?.let { saveClip(it) }
        } else {
            part.delete()
        }

        val fatalWarning = when (errorCode) {
            VideoRecordEvent.Finalize.ERROR_NONE,
            VideoRecordEvent.Finalize.ERROR_DURATION_LIMIT_REACHED,
            VideoRecordEvent.Finalize.ERROR_FILE_SIZE_LIMIT_REACHED -> null

            VideoRecordEvent.Finalize.ERROR_INSUFFICIENT_STORAGE ->
                "low_storage"

            VideoRecordEvent.Finalize.ERROR_SOURCE_INACTIVE ->
                "camera_error"

            else -> if (hasError) "recorder_error" else null
        }

        // Storage problems and an asked stop end the session; an encoder or
        // camera hiccup is retried, so one bad segment does not end the drive.
        val recoverable = fatalWarning != null &&
            fatalWarning != "low_storage" &&
            fatalWarning != "storage_error"

        // A zero-byte segment that nobody asked to stop would otherwise loop forever.
        if (!hasData && !stopRequested) {
            if (recoverable) {
                scheduleCameraRetry("Recording produced no data ($errorCode)")
            } else {
                setWarning(
                    fatalWarning ?: "recorder_error",
                    "Recording produced no data ($errorCode)",
                )
                finishSession()
            }
            return
        }

        if (stopRequested) {
            finishSession()
        } else if (recoverable) {
            scheduleCameraRetry("Recording error ($errorCode)")
        } else if (fatalWarning != null) {
            setWarning(fatalWarning, "Recording error ($errorCode)")
            finishSession()
        } else {
            startNextSegment()
        }
    }

    /** Moving a clip into a picked folder copies it, so it stays off the recorder thread. */
    private fun saveClip(clip: File) {
        val protected = File(clip.parentFile, clip.name + ".protected").exists()
        val cutoff = if (destroyAfterMinutes > 0) {
            System.currentTimeMillis() - destroyAfterMinutes * 60_000L
        } else {
            0L
        }
        io.execute {
            val used = runCatching {
                val set = repos ?: ClipRepos.create(this).also { repos = it }
                if (!set.save(clip, protected)) return@runCatching null
                set.expireBefore(cutoff)
                set.enforceBudget(budgetBytes)
            }.getOrNull()
            mainHandler.post {
                if (used != null) usedBytesCache = used
                emitStatus()
            }
        }
    }

    private fun refreshUsage() {
        io.execute {
            val used = runCatching {
                val set = repos ?: ClipRepos.create(this).also { repos = it }
                set.usedBytes()
            }.getOrDefault(0L)
            mainHandler.post {
                usedBytesCache = used
                emitStatus()
            }
        }
    }

    private fun finishSession() {
        mainHandler.removeCallbacks(stopWatchdog)
        mainHandler.removeCallbacks(cameraRetry)
        clearAutoNotification()
        recordingRequested = false
        stopRequested = false
        autoStarted = false
        cameraRetries = 0
        currentPart = null
        releaseWakeLock()
        stopTicker()
        stopCrashDetection()

        if (stopServiceWhenFinalized) {
            stopServiceWhenFinalized = false
            updateNotification()
            emitStatus()
            stopSelf()
            return
        }
        if (!activityVisible) {
            stopSelf()
            return
        }
        state = if (session.isBound) "previewing" else "idle"
        updateNotification()
        emitStatus()
    }

    private fun failRecording(code: String, message: String) {
        setWarning(code, message)
        clearAutoNotification()
        recordingRequested = false
        stopRequested = false
        releaseWakeLock()
        stopTicker()
        stopCrashDetection()
        state = if (session.isBound) "previewing" else "idle"
        updateNotification()
        emitStatus()
    }

    private fun stopWithWarning(code: String, message: String) {
        if (!recordingRequested) return
        setWarning(code, message)
        stopRequested = true
        state = "stopping"
        if (session.isRecording) {
            session.stopSegment()
            mainHandler.postDelayed(stopWatchdog, STOP_TIMEOUT_MS)
        } else {
            finishSession()
            return
        }
        updateNotification()
        emitStatus()
    }

    private fun checkFreeSpace() {
        if (!recordingRequested) return
        val dir = ClipStore.clipDir(this) ?: return
        val free = ClipStore.freeBytes(dir)
        if (free == null) {
            stopWithWarning("storage_error", "Cannot read free space")
        } else if (free < LOW_SPACE_BYTES) {
            stopWithWarning("low_storage", "Less than 500 MB free")
        }
    }

    private fun setWarning(code: String, message: String) {
        warning = code
        lastError = message
        ClipStore.clipDir(this)?.let { ClipStore.writeWarning(it, code) }
    }

    private fun clearWarning() {
        warning = null
        ClipStore.clipDir(this)?.let { ClipStore.writeWarning(it, null) }
    }

    private fun config() = CameraSession.Config(
        front = camera == "front",
        resolution = resolution,
        dataSaver = dataSaver,
        audio = audio,
        stamp = stamp,
        zone = zone,
    )

    private fun resolutionFor(intent: Intent): String {
        val wire = intent.getStringExtra(EXTRA_RESOLUTION)
        return if (wire in RESOLUTION_VALUES) wire!! else "1080p"
    }

    private fun displayRotation(): Int {
        val manager = getSystemService(DisplayManager::class.java)
        return manager?.getDisplay(Display.DEFAULT_DISPLAY)?.rotation
            ?: Surface.ROTATION_0
    }

    private fun startCrashDetection() {
        if (crashDetector != null) return
        val manager = getSystemService(SensorManager::class.java) ?: return
        val sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            ?: return
        val threshold = CrashSensitivity.thresholdMps2(
            sensitivity,
            sensor.maximumRange,
        )
        crashDetector = CrashDetector(threshold)
        sensorManager = manager
        val registered = manager.registerListener(
            accelerationListener,
            sensor,
            SensorManager.SENSOR_DELAY_GAME,
            mainHandler,
        )
        if (!registered) {
            sensorManager = null
            crashDetector = null
        }
    }

    private fun stopCrashDetection() {
        sensorManager?.unregisterListener(accelerationListener)
        sensorManager = null
        crashDetector = null
    }

    private fun startTicker() {
        if (tickerRunning) return
        tickerRunning = true
        spaceTickCounter = 0
        mainHandler.postDelayed(ticker, TICK_MS)
    }

    private fun stopTicker() {
        tickerRunning = false
        mainHandler.removeCallbacks(ticker)
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val manager = getSystemService(PowerManager::class.java)
            wakeLock = manager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "reason:recording",
            ).apply { setReferenceCounted(false) }
        }
        wakeLock?.acquire(WAKE_LOCK_TIMEOUT_MS)
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
    }

    private fun emitStatus() {
        StatusBus.emit(statusMap())
    }

    private fun clearAutoNotification() {
        runCatching {
            getSystemService(NotificationManager::class.java)
                ?.cancel(AUTO_NOTIFICATION_ID)
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setShowBadge(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, RecorderService::class.java)
                .setAction(ACTION_NOTIFICATION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val title = when {
            warning == "low_storage" ->
                getString(R.string.notification_warning_low_storage)

            warning == "storage_error" ->
                getString(R.string.notification_warning_storage_error)

            warning == "camera_error" ->
                getString(R.string.notification_warning_camera_error)

            warning == "recorder_error" ->
                getString(R.string.notification_warning_recorder_error)

            recordingRequested -> getString(R.string.notification_recording)

            state == "previewing" || state == "starting" ->
                getString(R.string.notification_previewing)

            else -> getString(R.string.notification_ready)
        }
        val text = if (state == "previewing" || state == "starting") {
            getString(R.string.notification_preview_text)
        } else {
            getString(R.string.notification_open)
        }
        val actionLabel = if (recordingRequested) {
            getString(R.string.notification_stop_recording)
        } else {
            getString(R.string.notification_close_preview)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_record)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openIntent)
            .addAction(R.drawable.ic_stat_record, actionLabel, stopIntent)
            .setForegroundServiceBehavior(
                NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE,
            )
            .build()
    }

    private fun updateNotification() {
        if (instance == null) return
        runCatching {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA,
            )
        }
    }
}
