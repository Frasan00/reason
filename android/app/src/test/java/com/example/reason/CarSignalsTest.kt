package com.example.reason

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CarSignalsTest {
    @Test
    fun bluetoothLinkIsEnough() {
        assertTrue(CarSignals.inCar(1, false, false, 0L, 1_000L))
    }

    @Test
    fun activityTransitionIsEnough() {
        assertTrue(CarSignals.inCar(0, true, false, 0L, 1_000L))
    }

    @Test
    fun chargingWithRecentMotionIsEnough() {
        val now = 10 * 60_000L
        assertTrue(
            CarSignals.inCar(0, false, true, now - 60_000L, now),
        )
    }

    @Test
    fun chargingAloneIsNotEnough() {
        assertFalse(CarSignals.inCar(0, false, true, 0L, 1_000L))
    }

    @Test
    fun motionExpires() {
        val now = 20 * 60_000L
        assertFalse(
            CarSignals.inCar(
                0,
                false,
                true,
                now - CarSignals.MOTION_HOLD_MS - 1,
                now,
            ),
        )
    }

    @Test
    fun motionWithoutChargingIsNotEnough() {
        val now = 10 * 60_000L
        assertFalse(CarSignals.inCar(0, false, false, now - 1_000L, now))
    }
}
