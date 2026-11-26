package com.example.reason

import kotlin.math.sqrt

class CrashDetector(
    private val thresholdMps2: Float,
    private val lockWindowMs: Long = 60_000L,
) {
    private val gravity = FloatArray(3)
    private var initialized = false
    private var lastLockElapsedMs = Long.MIN_VALUE

    fun onSample(
        x: Float,
        y: Float,
        z: Float,
        nowElapsedMs: Long,
    ): Boolean {
        if (!initialized) {
            gravity[0] = x
            gravity[1] = y
            gravity[2] = z
            initialized = true
            return false
        }

        // Low-pass gravity estimate; the residual is the impact signal.
        gravity[0] = ALPHA * gravity[0] + (1 - ALPHA) * x
        gravity[1] = ALPHA * gravity[1] + (1 - ALPHA) * y
        gravity[2] = ALPHA * gravity[2] + (1 - ALPHA) * z

        val dx = x - gravity[0]
        val dy = y - gravity[1]
        val dz = z - gravity[2]
        if (sqrt(dx * dx + dy * dy + dz * dz) < thresholdMps2) return false

        if (lastLockElapsedMs != Long.MIN_VALUE &&
            nowElapsedMs - lastLockElapsedMs < lockWindowMs
        ) {
            return false
        }
        lastLockElapsedMs = nowElapsedMs
        return true
    }

    private companion object {
        const val ALPHA = 0.8f
    }
}
