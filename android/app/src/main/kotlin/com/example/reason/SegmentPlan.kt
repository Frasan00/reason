package com.example.reason

object SegmentPlan {
    const val MIN_LIMIT_MS = 5_000L

    // Shortening the next segment by the finalize gap keeps start-to-start cadence nominal.
    fun nextLimitMs(
        nowElapsedMs: Long,
        sessionStartElapsedMs: Long,
        nextIndex: Int,
        segmentMs: Long,
    ): Long {
        val targetEnd = sessionStartElapsedMs + (nextIndex + 1).toLong() * segmentMs
        return (targetEnd - nowElapsedMs).coerceIn(MIN_LIMIT_MS, segmentMs)
    }
}
