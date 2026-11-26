package com.example.reason

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** The text burned into the frame, kept separate so it can be tested. */
object StampFormat {
    /** One formatter per zone; SimpleDateFormat is costly to build and not thread safe. */
    fun formatter(zoneId: String?): SimpleDateFormat =
        SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
            .apply { timeZone = zone(zoneId) }

    fun text(epochMs: Long, zoneId: String?): String =
        formatter(zoneId).format(Date(epochMs))

    fun zone(zoneId: String?): TimeZone =
        if (zoneId.isNullOrEmpty()) TimeZone.getDefault() else TimeZone.getTimeZone(zoneId)
}
