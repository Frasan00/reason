package com.example.reason

import org.junit.Assert.assertEquals
import org.junit.Test

class RetentionPlanTest {
    private val old = "1600000000000.mp4" to 1_000L
    private val middle = "1600000100000.mp4" to 2_000L
    private val recent = "1600000200000.mp4" to 3_000L

    @Test
    fun `no cutoff deletes nothing`() {
        assertEquals(
            emptyList<String>(),
            RetentionPlan.expired(listOf(old, middle, recent), emptySet(), 0),
        )
    }

    @Test
    fun `clips older than the cutoff are removed`() {
        assertEquals(
            listOf(old.name(), middle.name()),
            RetentionPlan.expired(listOf(old, middle, recent), emptySet(), 2_500),
        )
    }

    @Test
    fun `a clip started at the cutoff is kept`() {
        assertEquals(
            listOf(old.name()),
            RetentionPlan.expired(listOf(old, middle, recent), emptySet(), 2_000),
        )
    }

    @Test
    fun `protected clips are kept`() {
        assertEquals(
            listOf(middle.name()),
            RetentionPlan.expired(
                listOf(old, middle, recent),
                setOf(old.name()),
                2_500,
            ),
        )
    }

    @Test
    fun `the newest clip survives even when every clip is expired`() {
        assertEquals(
            listOf(old.name(), middle.name()),
            RetentionPlan.expired(listOf(old, middle, recent), emptySet(), 9_000),
        )
    }

    @Test
    fun `the newest protected clip does not save the others`() {
        assertEquals(
            listOf(old.name(), middle.name()),
            RetentionPlan.expired(
                listOf(old, middle, recent),
                setOf(recent.name()),
                9_000,
            ),
        )
    }

    @Test
    fun `an empty list is fine`() {
        assertEquals(
            emptyList<String>(),
            RetentionPlan.expired(emptyList(), emptySet(), 9_000),
        )
    }

    private fun Pair<String, Long>.name() = first
}
