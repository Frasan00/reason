package com.example.reason

object CrashSensitivity {
    private const val STANDARD_GRAVITY = 9.80665f

    fun thresholdMps2(preset: String?, maxRangeMps2: Float): Float {
        val g = when (preset) {
            "low" -> 2.0f
            "high" -> 1.0f
            else -> 1.5f
        }
        val requested = g * STANDARD_GRAVITY
        if (maxRangeMps2 <= 0f) return requested
        return minOf(requested, maxRangeMps2 * 0.95f)
    }
}
