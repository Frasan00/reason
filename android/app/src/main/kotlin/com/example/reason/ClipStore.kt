package com.example.reason

import android.content.Context
import android.os.Environment
import java.io.File

object ClipStore {
    val clipName = Regex("^(\\d{13})\\.mp4$")
    private val startMsName = Regex("\\d{13}")
    private const val partSuffix = ".mp4.part"
    private const val warningName = ".last_warning"
    private val warningCodes = setOf(
        "low_storage",
        "storage_error",
        "camera_error",
        "recorder_error",
    )

    fun clipDir(context: Context): File? =
        context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)

    fun completedClips(dir: File): List<File> =
        dir.listFiles()
            ?.filter { it.isFile && clipName.matches(it.name) }
            ?.sortedBy { it.name }
            .orEmpty()

    fun usedBytes(dir: File): Long = completedClips(dir).sumOf { it.length() }

    fun isProtected(clip: File): Boolean =
        File(clip.parentFile, clip.name + ".protected").exists()

    fun partFile(dir: File, startMs: Long): File =
        File(dir, "$startMs$partSuffix")

    fun finalizePart(part: File): File? {
        if (!part.name.endsWith(partSuffix)) return null
        val clip = File(part.parentFile, part.name.removeSuffix(partSuffix) + ".mp4")
        if (clip.exists()) {
            part.delete()
            return null
        }
        return if (part.renameTo(clip)) clip else null
    }

    fun protectPart(part: File): Boolean {
        if (!part.name.endsWith(partSuffix)) return false
        val base = part.name.removeSuffix(partSuffix)
        if (!startMsName.matches(base)) return false
        val marker = File(part.parentFile, "$base.mp4.protected")
        return runCatching {
            marker.createNewFile()
            marker.exists()
        }.getOrDefault(false)
    }

    fun findClip(dir: File, name: String?): File? {
        if (name == null || !clipName.matches(name)) return null
        return File(dir, name).takeIf { it.isFile }
    }

    fun deleteClip(dir: File, name: String?): Boolean {
        val clip = findClip(dir, name) ?: return false
        val deleted = clip.delete()
        if (deleted) {
            File(clip.parentFile, clip.name + ".protected").delete()
        }
        return deleted
    }

    fun clearProtection(dir: File, name: String?): Boolean {
        val clip = findClip(dir, name) ?: return false
        val marker = File(clip.parentFile, clip.name + ".protected")
        return marker.delete() || !marker.exists()
    }

    fun cleanupInterrupted(dir: File) {
        dir.listFiles()?.forEach { file ->
            if (file.isFile &&
                (file.name.endsWith(partSuffix) || file.name.endsWith(".tmp"))
            ) {
                file.delete()
            }
        }
    }

    fun enforceBudget(dir: File, budgetBytes: Long): Long {
        var remaining = usedBytes(dir)
        if (budgetBytes <= 0) return remaining
        for (clip in completedClips(dir)) {
            if (remaining <= budgetBytes) break
            if (isProtected(clip)) continue
            val size = clip.length()
            if (clip.delete()) remaining -= size
        }
        return remaining
    }

    fun freeBytes(dir: File): Long? =
        runCatching { dir.usableSpace.takeIf { it > 0 } }.getOrNull()

    fun readWarning(dir: File): String? =
        runCatching {
            File(dir, warningName).takeIf { it.isFile }?.readText()?.trim()
        }.getOrNull()?.takeIf { it in warningCodes }

    fun writeWarning(dir: File, warning: String?) {
        val file = File(dir, warningName)
        if (warning == null) {
            file.delete()
            return
        }
        runCatching { file.writeText(warning) }
    }
}
