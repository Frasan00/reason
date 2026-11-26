package com.example.reason

/** Pure fusion of the car signals, testable without Android. */
object CarSignals {
    const val MOTION_HOLD_MS = 10 * 60_000L

    fun inCar(
        bluetoothLinks: Int,
        activityInVehicle: Boolean,
        charging: Boolean,
        lastMotionElapsed: Long,
        nowElapsed: Long,
    ): Boolean {
        if (bluetoothLinks > 0 || activityInVehicle) return true
        if (!charging || lastMotionElapsed <= 0L) return false
        return nowElapsed - lastMotionElapsed < MOTION_HOLD_MS
    }
}
