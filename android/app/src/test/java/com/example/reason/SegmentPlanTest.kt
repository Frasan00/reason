package com.example.reason

import org.junit.Assert.assertEquals
import org.junit.Test

class SegmentPlanTest {
    @Test
    fun `first segment gets the nominal limit`() {
        assertEquals(
            180_000L,
            SegmentPlan.nextLimitMs(1_000L, 1_000L, 0, 180_000L),
        )
    }

    @Test
    fun `a late start shortens the limit by the gap`() {
        assertEquals(
            179_700L,
            SegmentPlan.nextLimitMs(181_300L, 1_000L, 1, 180_000L),
        )
    }

    @Test
    fun `a stalled start clamps to the minimum`() {
        assertEquals(
            SegmentPlan.MIN_LIMIT_MS,
            SegmentPlan.nextLimitMs(400_000L, 1_000L, 1, 180_000L),
        )
    }

    @Test
    fun `the limit never exceeds the nominal`() {
        assertEquals(
            180_000L,
            SegmentPlan.nextLimitMs(0L, 0L, 0, 180_000L),
        )
    }
}
