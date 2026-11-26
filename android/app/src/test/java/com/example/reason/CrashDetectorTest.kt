package com.example.reason

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CrashDetectorTest {
    private val g = 9.80665f

    private fun settle(detector: CrashDetector, fromMs: Long, samples: Int) {
        for (i in 0 until samples) {
            detector.onSample(0f, 0f, g, fromMs + i * 20L)
        }
    }

    @Test
    fun `gravity alone does not trigger`() {
        val detector = CrashDetector(1.0f * g)

        assertFalse(detector.onSample(0f, 0f, g, 0L))
        assertFalse(detector.onSample(0f, 0f, g, 20L))
        assertFalse(detector.onSample(0f, 0f, g, 40L))
    }

    @Test
    fun `a spike above the threshold triggers`() {
        val detector = CrashDetector(1.0f * g)
        detector.onSample(0f, 0f, g, 0L)

        assertTrue(detector.onSample(0f, 0f, g + 20f, 20L))
    }

    @Test
    fun `a second spike inside the window is ignored`() {
        val detector = CrashDetector(1.0f * g, 60_000L)
        detector.onSample(0f, 0f, g, 0L)
        assertTrue(detector.onSample(0f, 0f, g + 20f, 20L))
        settle(detector, 40L, 20)

        assertFalse(detector.onSample(0f, 0f, g + 20f, 30_000L))
    }

    @Test
    fun `a spike after the window triggers again`() {
        val detector = CrashDetector(1.0f * g, 60_000L)
        detector.onSample(0f, 0f, g, 0L)
        assertTrue(detector.onSample(0f, 0f, g + 20f, 20L))
        settle(detector, 40L, 20)

        assertTrue(detector.onSample(0f, 0f, g + 20f, 60_020L))
    }

    @Test
    fun `a sample below the threshold does not trigger`() {
        val detector = CrashDetector(1.5f * g)
        detector.onSample(0f, 0f, g, 0L)

        assertFalse(detector.onSample(0f, 0f, g + 5f, 20L))
    }
}
