package com.example.reason

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class ClipStoreTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private fun file(name: String, bytes: Int = 10): File {
        val file = File(tmp.root, name)
        file.writeBytes(ByteArray(bytes))
        return file
    }

    @Test
    fun `lists only completed clips in chronological order`() {
        file("1700000000002.mp4")
        file("1700000000001.mp4")
        file("1700000000003.mp4.part")
        file("notes.txt")

        assertEquals(
            listOf("1700000000001.mp4", "1700000000002.mp4"),
            ClipStore.completedClips(tmp.root).map { it.name },
        )
    }

    @Test
    fun `used bytes counts only completed clips`() {
        file("1700000000001.mp4", 8)
        file("1700000000002.mp4", 12)
        file("1700000000003.mp4.part", 100)

        assertEquals(20L, ClipStore.usedBytes(tmp.root))
    }

    @Test
    fun `deletes the oldest unprotected clips until under budget`() {
        file("1700000000001.mp4", 100)
        file("1700000000002.mp4", 100)
        file("1700000000003.mp4", 100)

        val remaining = ClipStore.enforceBudget(tmp.root, 150)

        assertTrue(remaining <= 150)
        assertEquals(
            listOf("1700000000003.mp4"),
            ClipStore.completedClips(tmp.root).map { it.name },
        )
    }

    @Test
    fun `skips protected clips`() {
        file("1700000000001.mp4", 100)
        file("1700000000001.mp4.protected")
        file("1700000000002.mp4", 100)
        file("1700000000003.mp4", 100)

        ClipStore.enforceBudget(tmp.root, 150)

        assertEquals(
            listOf("1700000000001.mp4"),
            ClipStore.completedClips(tmp.root).map { it.name },
        )
    }

    @Test
    fun `all protected keeps the files`() {
        file("1700000000001.mp4", 100)
        file("1700000000001.mp4.protected")
        file("1700000000002.mp4", 100)
        file("1700000000002.mp4.protected")

        val remaining = ClipStore.enforceBudget(tmp.root, 50)

        assertEquals(200L, remaining)
        assertEquals(2, ClipStore.completedClips(tmp.root).size)
    }

    @Test
    fun `finalizes a part file`() {
        val part = ClipStore.partFile(tmp.root, 1700000000001L)
        part.writeBytes(ByteArray(4))

        val clip = ClipStore.finalizePart(part)

        assertNotNull(clip)
        assertEquals("1700000000001.mp4", clip!!.name)
        assertFalse(part.exists())
        assertTrue(clip.exists())
    }

    @Test
    fun `cleanup removes interrupted parts and temp files`() {
        val part = file("1700000000001.mp4.part")
        val temp = file("scratch.tmp")
        val clip = file("1700000000002.mp4")

        ClipStore.cleanupInterrupted(tmp.root)

        assertFalse(part.exists())
        assertFalse(temp.exists())
        assertTrue(clip.exists())
    }

    @Test
    fun `warning round trips and ignores unknown codes`() {
        ClipStore.writeWarning(tmp.root, "low_storage")
        assertEquals("low_storage", ClipStore.readWarning(tmp.root))

        ClipStore.writeWarning(tmp.root, "not_a_code")
        assertNull(ClipStore.readWarning(tmp.root))

        ClipStore.writeWarning(tmp.root, null)
        assertNull(ClipStore.readWarning(tmp.root))
    }

    @Test
    fun `protectPart creates an idempotent sibling marker`() {
        val part = ClipStore.partFile(tmp.root, 1700000000001L)
        part.writeBytes(ByteArray(4))

        assertTrue(ClipStore.protectPart(part))
        assertTrue(File(tmp.root, "1700000000001.mp4.protected").exists())
        assertTrue(ClipStore.protectPart(part))
    }

    @Test
    fun `a protected part survives finalize and budget enforcement`() {
        val part = ClipStore.partFile(tmp.root, 1700000000001L)
        part.writeBytes(ByteArray(100))
        assertTrue(ClipStore.protectPart(part))
        val clip = ClipStore.finalizePart(part)
        assertNotNull(clip)
        file("1700000000002.mp4", 100)

        ClipStore.enforceBudget(tmp.root, 50)

        assertTrue(clip!!.exists())
        assertEquals(
            listOf("1700000000001.mp4"),
            ClipStore.completedClips(tmp.root).map { it.name },
        )
    }

    @Test
    fun `findClip rejects paths and unknown names`() {
        val clip = file("1700000000001.mp4")

        assertEquals(clip, ClipStore.findClip(tmp.root, "1700000000001.mp4"))
        assertNull(ClipStore.findClip(tmp.root, "../1700000000001.mp4"))
        assertNull(ClipStore.findClip(tmp.root, "notes.txt"))
        assertNull(ClipStore.findClip(tmp.root, "1799999999999.mp4"))
        assertNull(ClipStore.findClip(tmp.root, null))
    }

    @Test
    fun `deleteClip removes the clip and its marker`() {
        val clip = file("1700000000001.mp4")
        val marker = file("1700000000001.mp4.protected")

        assertTrue(ClipStore.deleteClip(tmp.root, clip.name))

        assertFalse(clip.exists())
        assertFalse(marker.exists())
    }

    @Test
    fun `clearProtection removes only the marker`() {
        val clip = file("1700000000001.mp4")
        val marker = file("1700000000001.mp4.protected")

        assertTrue(ClipStore.clearProtection(tmp.root, clip.name))

        assertTrue(clip.exists())
        assertFalse(marker.exists())
    }
}
