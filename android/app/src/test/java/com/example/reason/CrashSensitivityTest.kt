package com.example.reason

import org.junit.Assert.assertEquals
import org.junit.Test

class CrashSensitivityTest {
    @Test
    fun `presets map to linear g`() {
        assertEquals(
            9.80665f,
            CrashSensitivity.thresholdMps2("high", 100f),
            0.01f,
        )
        assertEquals(
            14.709975f,
            CrashSensitivity.thresholdMps2("normal", 100f),
            0.01f,
        )
        assertEquals(
            19.6133f,
            CrashSensitivity.thresholdMps2("low", 100f),
            0.01f,
        )
    }

    @Test
    fun `the threshold is capped by the sensor range`() {
        assertEquals(
            19.0f,
            CrashSensitivity.thresholdMps2("low", 20f),
            0.01f,
        )
        assertEquals(
            9.80665f,
            CrashSensitivity.thresholdMps2("high", 20f),
            0.01f,
        )
    }

    @Test
    fun `an unknown preset uses normal`() {
        assertEquals(
            14.709975f,
            CrashSensitivity.thresholdMps2("wild", 100f),
            0.01f,
        )
        assertEquals(
            14.709975f,
            CrashSensitivity.thresholdMps2(null, 100f),
            0.01f,
        )
    }
}
