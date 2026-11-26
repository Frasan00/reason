package com.example.reason

import android.content.Context
import android.view.Surface
import android.view.View
import androidx.camera.view.PreviewView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PreviewViewFactory :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView {
        val view = PreviewView(context).apply {
            implementationMode = PreviewView.ImplementationMode.COMPATIBLE
            scaleType = PreviewView.ScaleType.FILL_CENTER
        }
        val surfaceProvider = view.surfaceProvider
        PreviewRegistry.provider = surfaceProvider
        RecorderService.instance?.attachPreview(surfaceProvider)

        val rotationListener =
            View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
                RecorderService.instance?.setPreviewRotation(
                    v.display?.rotation ?: Surface.ROTATION_0,
                )
            }
        view.addOnLayoutChangeListener(rotationListener)

        return object : PlatformView {
            override fun getView(): View = view

            override fun dispose() {
                view.removeOnLayoutChangeListener(rotationListener)
                PreviewRegistry.clear(surfaceProvider)
                RecorderService.instance?.detachPreview(surfaceProvider)
            }
        }
    }
}
