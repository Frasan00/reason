package com.example.reason

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.TimeZone

class StampFormatTest {
    private val instant = 1_795_000_000_000L

    @Test
    fun `formats the date and time in the chosen zone`() {
        assertEquals("2026-11-18 12:06:40", StampFormat.text(instant, "Europe/Rome"))
        assertEquals(
            "2026-11-18 06:06:40",
            StampFormat.text(instant, "America/New_York"),
        )
        assertEquals("2026-11-18 11:06:40", StampFormat.text(instant, "UTC"))
    }

    @Test
    fun `an unknown zone falls back to GMT instead of crashing`() {
        assertEquals("2026-11-18 11:06:40", StampFormat.text(instant, "Nowhere/City"))
    }

    @Test
    fun `a missing zone follows the phone`() {
        val previous = TimeZone.getDefault()
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Asia/Tokyo"))
            assertEquals("2026-11-18 20:06:40", StampFormat.text(instant, null))
        } finally {
            TimeZone.setDefault(previous)
        }
    }
}
