package com.example.reason

import android.Manifest
import android.app.Activity
import android.app.LocaleManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.LocaleList
import androidx.camera.core.CameraSelector
import androidx.camera.core.DynamicRange
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.Quality
import androidx.camera.video.Recorder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class RecorderPlugin(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val context: Context = activity.applicationContext
    private val methodChannel = MethodChannel(messenger, "reason/recorder")
    private val eventChannel = EventChannel(messenger, "reason/recorder_events")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()

    private var carDetector: CarDetector? = null
    private var carSignals = CarDetector.Signals(true, true, true)
    private var folderResult: MethodChannel.Result? = null
    private var carCamera = "rear"
    private var carResolution = "1080p"
    private var carSegmentMinutes = 3
    private var carBudgetBytes = StatusBus.DEFAULT_BUDGET_BYTES
    private var carSensitivity = "normal"
    private var carDataSaver = false
    private var carDestroyAfterMinutes = 0
    private var activityVisible = false

    fun register() {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun setActivityVisible(visible: Boolean) {
        activityVisible = visible
    }

    /** The activity is going away: stop the detector and the worker thread. */
    fun dispose() {
        runCatching { carDetector?.stop() }
        carDetector = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> getCapabilities(result)
            "startPreview" -> startPreview(call, result)
            "startRecording" -> startRecording(call, result)
            "stopRecording" -> {
                if (RecorderService.instance != null) {
                    send(RecorderService.ACTION_STOP_RECORDING)
                }
                result.success(null)
            }

            "stopPreview" -> stopPreview(result)

            "setOrientationLocked" -> {
                val locked = call.arguments as? Boolean ?: false
                activity.requestedOrientation = if (locked) {
                    ActivityInfo.SCREEN_ORIENTATION_LOCKED
                } else {
                    ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                }
                result.success(null)
            }

            "getStatus" -> result.success(currentStatus())
            "listClips" -> listClips(result)
            "deleteClip" -> deleteClip(call, result)
            "clearProtection" -> clearProtection(call, result)
            "shareClip" -> shareClip(call, result)
            "setCarMode" -> setCarMode(call, result)
            "clearCarMode" -> {
                carDetector?.stop()
                carDetector = null
                result.success(null)
            }

            "pickStorageFolder" -> pickStorageFolder(result)
            "setStorageFolder" -> setStorageFolder(call, result)

            "applyRetention" -> applyRetention(call, result)
            "setLanguage" -> setLanguage(call, result)

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        StatusBus.sink = events
        events?.success(currentStatus())
    }

    override fun onCancel(arguments: Any?) {
        StatusBus.sink = null
    }

    private fun startPreview(call: MethodCall, result: MethodChannel.Result) {
        val camera = call.argument<String>("camera")
        val resolution = call.argument<String>("resolution")
        if (camera == null || camera !in CAMERA_VALUES ||
            resolution == null || resolution !in RESOLUTION_VALUES
        ) {
            result.error("invalid_args", "Unknown camera or resolution", null)
            return
        }
        if (RecorderService.instance?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        if (!cameraGranted()) {
            result.error(
                "permission_denied",
                "Camera permission is not granted",
                null,
            )
            return
        }
        try {
            send(RecorderService.ACTION_START_PREVIEW) {
                putExtra(RecorderService.EXTRA_CAMERA, camera)
                putExtra(RecorderService.EXTRA_RESOLUTION, resolution)
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("foreground_service_failed", error.message, null)
        }
    }

    private fun startRecording(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val camera = call.argument<String>("camera")
        val resolution = call.argument<String>("resolution")
        val segmentMinutes =
            (call.argument<Any>("segmentMinutes") as? Number)?.toInt() ?: 3
        val budgetBytes =
            (call.argument<Any>("budgetBytes") as? Number)?.toLong()
                ?: StatusBus.DEFAULT_BUDGET_BYTES
        val sensitivity = call.argument<String>("sensitivity") ?: "normal"
        val dataSaver = call.argument<Boolean>("dataSaver") ?: false
        val destroyAfterMinutes =
            (call.argument<Any>("destroyAfterMinutes") as? Number)?.toInt() ?: 0
        if (camera == null || camera !in CAMERA_VALUES ||
            resolution == null || resolution !in RESOLUTION_VALUES ||
            segmentMinutes !in 1..60 || budgetBytes <= 0 ||
            sensitivity !in SENSITIVITY_VALUES || destroyAfterMinutes < 0
        ) {
            result.error("invalid_args", "Invalid recording settings", null)
            return
        }
        if (!cameraGranted()) {
            result.error(
                "permission_denied",
                "Camera permission is not granted",
                null,
            )
            return
        }
        try {
            send(RecorderService.ACTION_START_RECORDING) {
                putExtra(RecorderService.EXTRA_CAMERA, camera)
                putExtra(RecorderService.EXTRA_RESOLUTION, resolution)
                putExtra(
                    RecorderService.EXTRA_SEGMENT_MINUTES,
                    segmentMinutes,
                )
                putExtra(RecorderService.EXTRA_BUDGET_BYTES, budgetBytes)
                putExtra(RecorderService.EXTRA_SENSITIVITY, sensitivity)
                putExtra(RecorderService.EXTRA_DATA_SAVER, dataSaver)
                putExtra(
                    RecorderService.EXTRA_DESTROY_AFTER_MINUTES,
                    destroyAfterMinutes,
                )
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("foreground_service_failed", error.message, null)
        }
    }

    private fun stopPreview(result: MethodChannel.Result) {
        val service = RecorderService.instance
        if (service?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        if (service != null) send(RecorderService.ACTION_STOP_SERVICE)
        result.success(null)
    }

    private fun listClips(result: MethodChannel.Result) {
        io.execute {
            val clips = runCatching {
                ClipRepos.create(context).list()
            }.getOrDefault(emptyList())
                .sortedByDescending { it.startEpochMs }
                .map { clip ->
                    mapOf(
                        "name" to clip.name,
                        "uri" to clip.uri.toString(),
                        "startEpochMs" to clip.startEpochMs,
                        "sizeBytes" to clip.sizeBytes,
                        "durationMs" to durationMs(clip.uri),
                        "protected" to clip.protected,
                    )
                }
            mainHandler.post { runCatching { result.success(clips) } }
        }
    }

    private fun durationMs(uri: Uri): Long = runCatching {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)
            retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION,
            )?.toLongOrNull() ?: 0L
        } finally {
            retriever.release()
        }
    }.getOrDefault(0L)

    private fun deleteClip(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (RecorderService.instance?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        val name = call.argument<String>("name") ?: ""
        io.execute {
            val deleted = runCatching {
                ClipRepos.create(context).delete(name)
            }.getOrDefault(false)
            mainHandler.post {
                if (deleted) {
                    result.success(null)
                } else {
                    result.error("clip_not_found", "Clip not found", null)
                }
            }
        }
    }

    private fun clearProtection(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (RecorderService.instance?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        val name = call.argument<String>("name") ?: ""
        io.execute {
            val cleared = runCatching {
                ClipRepos.create(context).clearProtection(name)
            }.getOrDefault(false)
            mainHandler.post {
                if (cleared) {
                    result.success(null)
                } else {
                    result.error("clip_not_found", "Clip not found", null)
                }
            }
        }
    }

    private fun shareClip(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (RecorderService.instance?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        val name = call.argument<String>("name")
        io.execute {
            val clip = runCatching {
                ClipRepos.create(context).list().firstOrNull { it.name == name }
            }.getOrNull()
            mainHandler.post {
                if (clip == null) {
                    result.error("clip_not_found", "Clip not found", null)
                    return@post
                }
                try {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "video/mp4"
                        putExtra(Intent.EXTRA_STREAM, clip.uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    activity.startActivity(
                        Intent.createChooser(
                            send,
                            context.getString(R.string.share_clip_title),
                        ),
                    )
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_failed", error.message, null)
                }
            }
        }
    }

    private fun setCarMode(call: MethodCall, result: MethodChannel.Result) {
        val camera = call.argument<String>("camera")
        val resolution = call.argument<String>("resolution")
        val segmentMinutes =
            (call.argument<Any>("segmentMinutes") as? Number)?.toInt() ?: 3
        val budgetBytes =
            (call.argument<Any>("budgetBytes") as? Number)?.toLong()
                ?: StatusBus.DEFAULT_BUDGET_BYTES
        val sensitivity = call.argument<String>("sensitivity") ?: "normal"
        val dataSaver = call.argument<Boolean>("dataSaver") ?: false
        val destroyAfterMinutes =
            (call.argument<Any>("destroyAfterMinutes") as? Number)?.toInt() ?: 0
        if (camera == null || camera !in CAMERA_VALUES ||
            resolution == null || resolution !in RESOLUTION_VALUES ||
            segmentMinutes !in 1..60 || budgetBytes <= 0 ||
            sensitivity !in SENSITIVITY_VALUES || destroyAfterMinutes < 0
        ) {
            result.error("invalid_args", "Invalid car mode settings", null)
            return
        }
        carCamera = camera
        carResolution = resolution
        carSegmentMinutes = segmentMinutes
        carBudgetBytes = budgetBytes
        carSensitivity = sensitivity
        carDataSaver = dataSaver
        carDestroyAfterMinutes = destroyAfterMinutes
        carSignals = CarDetector.Signals(
            bluetooth = call.argument<Boolean>("bluetooth") ?: true,
            motion = call.argument<Boolean>("motion") ?: true,
            activity = call.argument<Boolean>("activity") ?: true,
        )
        val detector = carDetector
        if (detector == null) {
            carDetector = CarDetector(
                context,
                carSignals,
                onEnter = ::startRecordingFromCar,
                onExit = ::stopAutoRecording,
            ).also { it.start() }
        } else {
            detector.updateSignals(carSignals)
        }
        result.success(null)
    }

    private fun startRecordingFromCar(reason: Int) {
        if (RecorderService.instance?.isRecordingSession == true) return
        if (!cameraGranted()) {
            notifyCarDetected()
            return
        }
        try {
            send(recordingIntent(auto = true))
            notifyAutoStarted(reason)
        } catch (error: Exception) {
            // Android may block a camera foreground service started from the
            // background; the notification turns it into one tap.
            notifyCarDetected()
        }
    }

    private fun stopAutoRecording() {
        val service = RecorderService.instance ?: return
        if (!service.autoStarted) return
        send(RecorderService.ACTION_STOP_RECORDING)
    }

    private fun recordingIntent(auto: Boolean): Intent =
        Intent(context, RecorderService::class.java)
            .setAction(RecorderService.ACTION_START_RECORDING)
            .putExtra(RecorderService.EXTRA_CAMERA, carCamera)
            .putExtra(RecorderService.EXTRA_RESOLUTION, carResolution)
            .putExtra(
                RecorderService.EXTRA_SEGMENT_MINUTES,
                carSegmentMinutes,
            )
            .putExtra(RecorderService.EXTRA_BUDGET_BYTES, carBudgetBytes)
            .putExtra(RecorderService.EXTRA_SENSITIVITY, carSensitivity)
            .putExtra(RecorderService.EXTRA_DATA_SAVER, carDataSaver)
            .putExtra(
                RecorderService.EXTRA_DESTROY_AFTER_MINUTES,
                carDestroyAfterMinutes,
            )
            .putExtra(RecorderService.EXTRA_AUTO, auto)

    private fun carChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        manager.createNotificationChannel(
            NotificationChannel(
                CAR_CHANNEL_ID,
                context.getString(R.string.notification_channel_car),
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
    }

    private fun openApp(): PendingIntent = PendingIntent.getActivity(
        context,
        4,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        },
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun notifyAutoStarted(reason: Int) {
        val manager = context.getSystemService(NotificationManager::class.java)
            ?: return
        carChannel(manager)
        val stop = PendingIntent.getService(
            context,
            5,
            Intent(context, RecorderService::class.java)
                .setAction(RecorderService.ACTION_STOP_RECORDING),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        runCatching {
            manager.notify(
                RecorderService.AUTO_NOTIFICATION_ID,
                NotificationCompat.Builder(context, CAR_CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_stat_record)
                    .setContentTitle(
                        context.getString(R.string.notification_auto_started),
                    )
                    .setContentText(
                        context.getString(
                            R.string.notification_auto_started_text,
                            context.getString(reason),
                        ),
                    )
                    .setContentIntent(openApp())
                    .addAction(
                        R.drawable.ic_stat_record,
                        context.getString(R.string.notification_stop_recording),
                        stop,
                    )
                    .setAutoCancel(true)
                    .build(),
            )
        }
    }

    private fun notifyCarDetected() {
        val manager = context.getSystemService(NotificationManager::class.java)
            ?: return
        carChannel(manager)
        val recordIntent = recordingIntent(auto = true)
        val record = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                context,
                3,
                recordIntent,
                PendingIntent.FLAG_IMMUTABLE or
                    PendingIntent.FLAG_UPDATE_CURRENT,
            )
        } else {
            PendingIntent.getService(
                context,
                3,
                recordIntent,
                PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
        runCatching {
            manager.notify(
                RecorderService.AUTO_NOTIFICATION_ID,
                NotificationCompat.Builder(context, CAR_CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_stat_record)
                    .setContentTitle(
                        context.getString(R.string.notification_car_detected),
                    )
                    .setContentText(
                        context.getString(
                            R.string.notification_car_detected_text,
                        ),
                    )
                    .setContentIntent(openApp())
                    .addAction(
                        R.drawable.ic_stat_record,
                        context.getString(R.string.notification_car_record),
                        record,
                    )
                    .setAutoCancel(true)
                    .build(),
            )
        }
    }

    private fun pickStorageFolder(result: MethodChannel.Result) {
        if (RecorderService.instance?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        if (folderResult != null) {
            result.error("picker_busy", "Folder picker is already open", null)
            return
        }
        folderResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        try {
            activity.startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (error: Exception) {
            folderResult = null
            result.error("picker_failed", error.message, null)
        }
    }

    fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        if (requestCode != REQUEST_PICK_FOLDER) return
        val result = folderResult ?: return
        folderResult = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) {
            result.success(null)
            return
        }
        try {
            context.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            val label = DocumentFile.fromTreeUri(context, uri)?.name
                ?: "Folder"
            ClipRepos.storeFolder(context, uri.toString(), label)
            result.success(mapOf("uri" to uri.toString(), "label" to label))
        } catch (error: Exception) {
            result.error("folder_unavailable", error.message, null)
        }
    }

    private fun setStorageFolder(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (RecorderService.instance?.isRecordingSession == true) {
            result.error("recording_in_progress", "Stop recording first", null)
            return
        }
        val uri = call.argument<String>("uri")
        if (uri.isNullOrEmpty()) {
            ClipRepos.storeFolder(context, null, null)
            result.success(null)
            return
        }
        runCatching {
            context.contentResolver.takePersistableUriPermission(
                Uri.parse(uri),
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        }
        val repo = runCatching { SafClipRepo(context, Uri.parse(uri)) }.getOrNull()
        if (repo == null) {
            // The folder was moved, deleted or unshared: stop promising it.
            ClipRepos.storeFolder(context, null, null)
            result.error("folder_unavailable", "Folder is not writable", null)
            return
        }
        ClipRepos.storeFolder(context, uri, repo.label)
        result.success(null)
    }

    /** Applies "destroy after" to clips that are already on disk. */
    private fun applyRetention(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val minutes = (call.argument<Any>("minutes") as? Number)?.toInt() ?: 0
        if (minutes <= 0) {
            result.success(null)
            return
        }
        val cutoff = System.currentTimeMillis() - minutes * 60_000L
        io.execute {
            runCatching { ClipRepos.create(context).expireBefore(cutoff) }
            mainHandler.post { result.success(null) }
        }
    }

    /** Per-app language so notifications follow the choice in Settings. */
    private fun setLanguage(call: MethodCall, result: MethodChannel.Result) {
        val language = call.argument<String>("language") ?: "system"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val locales = if (language == "system") {
                LocaleList.getEmptyLocaleList()
            } else {
                LocaleList.forLanguageTags(language)
            }
            runCatching {
                context.getSystemService(LocaleManager::class.java)
                    ?.applicationLocales = locales
            }
        }
        result.success(null)
    }

    private fun getCapabilities(result: MethodChannel.Result) {
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            try {
                result.success(capabilities(future.get()))
            } catch (error: Exception) {
                result.error("camera_provider_failed", error.message, null)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    private fun capabilities(
        provider: ProcessCameraProvider,
    ): Map<String, Any?> = mapOf(
        "rear" to cameraCapability(
            provider,
            CameraSelector.DEFAULT_BACK_CAMERA,
        ),
        "front" to cameraCapability(
            provider,
            CameraSelector.DEFAULT_FRONT_CAMERA,
        ),
    )

    private fun cameraCapability(
        provider: ProcessCameraProvider,
        selector: CameraSelector,
    ): Map<String, Any?> {
        val infos = selector.filter(provider.availableCameraInfos)
        val found = mutableSetOf<String>()
        for (info in infos) {
            runCatching {
                val qualities = Recorder.getVideoCapabilities(info)
                    .getSupportedQualities(DynamicRange.SDR)
                if (qualities.contains(Quality.FHD)) found.add("1080p")
                if (qualities.contains(Quality.HD)) found.add("720p")
                if (qualities.contains(Quality.QHD)) found.add("1440p")
                if (qualities.contains(Quality.SD)) found.add("480p")
            }
        }
        return mapOf(
            "available" to found.isNotEmpty(),
            "resolutions" to listOf("1440p", "1080p", "720p", "480p")
                .filter { it in found },
        )
    }

    private fun send(action: String, fill: Intent.() -> Unit = {}) {
        send(
            Intent(context, RecorderService::class.java)
                .setAction(action)
                .apply(fill),
        )
    }

    private fun send(intent: Intent) {
        intent.putExtra(RecorderService.EXTRA_VISIBLE, activityVisible)
        if (RecorderService.instance == null) {
            ContextCompat.startForegroundService(context, intent)
        } else {
            context.startService(intent)
        }
    }

    private fun cameraGranted(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED

    private fun currentStatus(): Map<String, Any?> =
        RecorderService.instance?.statusMap() ?: StatusBus.idleStatus(context)

    private companion object {
        const val CAR_CHANNEL_ID = "reason.car"
        const val REQUEST_PICK_FOLDER = 7101
        val CAMERA_VALUES = setOf("rear", "front")
        val RESOLUTION_VALUES = setOf("1440p", "1080p", "720p", "480p")
        val SENSITIVITY_VALUES = setOf("low", "normal", "high")
    }
}
