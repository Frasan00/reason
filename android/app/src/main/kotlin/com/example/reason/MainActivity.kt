package com.example.reason

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var recorderPlugin: RecorderPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        recorderPlugin = RecorderPlugin(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        ).also { it.register() }
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "reason/preview",
            PreviewViewFactory(),
        )
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        recorderPlugin?.onActivityResult(requestCode, resultCode, data)
    }

    override fun onStart() {
        super.onStart()
        recorderPlugin?.setActivityVisible(true)
        RecorderService.instance?.setActivityVisible(true)
    }

    override fun onStop() {
        recorderPlugin?.setActivityVisible(false)
        RecorderService.instance?.setActivityVisible(false)
        super.onStop()
    }

    override fun onDestroy() {
        recorderPlugin?.dispose()
        recorderPlugin = null
        super.onDestroy()
    }
}
