package com.example.reason

import android.content.Context
import android.media.MediaFormat
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FallbackStrategy
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.lifecycle.LifecycleOwner
import java.io.File
import java.util.concurrent.Executor

class CameraSession(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val mainExecutor: Executor,
    private val listener: Listener,
) {
    interface Listener {
        fun onCameraReady()
        fun onCameraError(message: String)
        fun onSegmentFinalized(part: File, errorCode: Int, hasError: Boolean)
    }

    data class Config(
        val front: Boolean,
        val resolution: String,
        val dataSaver: Boolean,
    )

    private var provider: ProcessCameraProvider? = null
    private var preview: Preview? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var recorder: Recorder? = null
    private var activeRecording: Recording? = null
    private var attachedProvider: Preview.SurfaceProvider? = null
    private var binding = false
    private var pendingConfig: Config? = null
    private var boundConfig: Config? = null
    private var released = false

    val isBound: Boolean
        get() = preview != null && videoCapture != null

    val isRecording: Boolean
        get() = activeRecording != null

    val config: Config?
        get() = boundConfig

    fun ensureBound(config: Config, rotation: Int) {
        if (released || isRecording) return
        if (boundConfig == config && isBound) {
            listener.onCameraReady()
            return
        }
        pendingConfig = config
        if (binding) return

        val existing = provider
        if (existing != null) {
            bindInternal(existing, config, rotation)
            return
        }

        binding = true
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            binding = false
            if (released) return@addListener
            try {
                val cameraProvider = future.get()
                provider = cameraProvider
                val target = pendingConfig ?: return@addListener
                bindInternal(cameraProvider, target, rotation)
            } catch (error: Exception) {
                listener.onCameraError(
                    error.message ?: "Camera provider unavailable",
                )
            }
        }, mainExecutor)
    }

    private fun bindInternal(
        cameraProvider: ProcessCameraProvider,
        config: Config,
        rotation: Int,
    ) {
        if (released) return
        try {
            cameraProvider.unbindAll()
            val selector = if (config.front) {
                CameraSelector.DEFAULT_FRONT_CAMERA
            } else {
                CameraSelector.DEFAULT_BACK_CAMERA
            }
            val quality = when (config.resolution) {
                "1440p" -> Quality.QHD
                "1080p" -> Quality.FHD
                "720p" -> Quality.HD
                else -> Quality.SD
            }
            val newRecorder = Recorder.Builder()
                .setQualitySelector(
                    QualitySelector.from(
                        quality,
                        FallbackStrategy.lowerQualityOrHigherThan(Quality.SD),
                    ),
                )
                .setVideoMimeType(MediaFormat.MIMETYPE_VIDEO_AVC)
                .apply {
                    if (config.dataSaver) {
                        setTargetVideoEncodingBitRate(
                            bitrateFor(config.resolution),
                        )
                    }
                }
                .build()
            val newVideoCapture = VideoCapture.withOutput(newRecorder)
            val newPreview = Preview.Builder().build().apply {
                targetRotation = rotation
            }
            val surfaceProvider = attachedProvider ?: PreviewRegistry.provider
            attachedProvider = surfaceProvider
            surfaceProvider?.let { newPreview.setSurfaceProvider(it) }
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                selector,
                newPreview,
                newVideoCapture,
            )
            recorder = newRecorder
            videoCapture = newVideoCapture
            preview = newPreview
            boundConfig = config
            listener.onCameraReady()
        } catch (error: Exception) {
            recorder = null
            videoCapture = null
            preview = null
            boundConfig = null
            listener.onCameraError(error.message ?: "Camera bind failed")
        }
    }

    fun attachPreview(provider: Preview.SurfaceProvider?) {
        attachedProvider = provider
        preview?.setSurfaceProvider(provider)
    }

    fun detachPreview(provider: Preview.SurfaceProvider) {
        if (attachedProvider === provider) {
            attachedProvider = null
            preview?.setSurfaceProvider(null)
        }
    }

    fun setPreviewRotation(rotation: Int) {
        preview?.targetRotation = rotation
    }

    /** Drops the cached binding so a camera lost to another app is bound again. */
    fun forceRebind(config: Config, rotation: Int) {
        if (released || isRecording) return
        boundConfig = null
        ensureBound(config, rotation)
    }

    fun startSegment(part: File, limitMs: Long, rotation: Int): Boolean {        if (released || activeRecording != null) return false
        val activeRecorder = recorder ?: return false
        val activeCapture = videoCapture ?: return false
        return try {
            activeCapture.targetRotation = rotation
            val options = FileOutputOptions.Builder(part)
                .setDurationLimitMillis(limitMs)
                .build()
            val pending = activeRecorder.prepareRecording(context, options)
            activeRecording = pending.start(mainExecutor) { event ->
                if (event is VideoRecordEvent.Finalize && !released) {
                    activeRecording = null
                    listener.onSegmentFinalized(
                        part,
                        event.error,
                        event.hasError(),
                    )
                }
            }
            true
        } catch (_: Exception) {
            activeRecording = null
            false
        }
    }

    fun stopSegment() {
        runCatching { activeRecording?.stop() }
    }

    /** Drops a recording that did not finalize, so a new segment can start. */
    fun abortRecording() {
        runCatching { activeRecording?.close() }
        activeRecording = null
    }

    // Roughly a third of the encoder profile bitrates, enough for a sharp
    // dash-cam picture at a much smaller size.
    private fun bitrateFor(resolution: String): Int = when (resolution) {
        "1440p" -> 8_000_000
        "1080p" -> 5_000_000
        "720p" -> 2_500_000
        else -> 1_200_000
    }

    fun release() {
        released = true
        runCatching { activeRecording?.close() }
        activeRecording = null
        // Unbind only this session's use cases: unbindAll could clear a newer session.
        val cameraProvider = provider
        val previewUseCase = preview
        val videoUseCase = videoCapture
        if (cameraProvider != null && previewUseCase != null && videoUseCase != null) {
            runCatching { cameraProvider.unbind(previewUseCase, videoUseCase) }
        }
        provider = null
        preview = null
        videoCapture = null
        recorder = null
        attachedProvider = null
        boundConfig = null
    }
}
