package com.example.reason

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object StatusBus {
    const val DEFAULT_BUDGET_BYTES = 2L * 1024L * 1024L * 1024L

    private val main = Handler(Looper.getMainLooper())

    @Volatile
    var sink: EventChannel.EventSink? = null

    fun emit(status: Map<String, Any?>) {
        main.post { runCatching { sink?.success(status) } }
    }

    fun idleStatus(context: Context): Map<String, Any?> {
        val dir = ClipStore.clipDir(context)
        return mapOf(
            "state" to "idle",
            "camera" to "rear",
            "resolution" to "1080p",
            "segmentMinutes" to 3,
            "budgetBytes" to DEFAULT_BUDGET_BYTES,
            "sessionElapsedMs" to 0L,
            "segmentIndex" to 0,
            "usedBytes" to (dir?.let { ClipStore.usedBytes(it) } ?: 0L),
            "freeBytes" to (dir?.let { ClipStore.freeBytes(it) } ?: 0L),
            "recording" to false,
            "warning" to (dir?.let { ClipStore.readWarning(it) }),
            "lastError" to null,
        )
    }
}
