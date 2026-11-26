package com.example.reason

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class ClipEntry(
    val name: String,
    val uri: Uri,
    val sizeBytes: Long,
    val startEpochMs: Long,
    val protected: Boolean,
    val repo: ClipRepository,
)

/** One place clips are stored: the app folder or a folder the user picked. */
interface ClipRepository {
    val label: String

    fun list(): List<ClipEntry>

    fun usedBytes(): Long = list().sumOf { it.sizeBytes }

    fun save(clip: File, protected: Boolean): Boolean

    fun delete(name: String): Boolean

    fun clearProtection(name: String): Boolean

    fun freeBytes(): Long?

    /** Deletes unprotected clips recorded before the cutoff; 0 means no cutoff. */
    fun expireBefore(cutoffMs: Long): Long {
        if (cutoffMs <= 0) return 0L
        val entries = list()
        val expired = RetentionPlan.expired(
            entries.map { it.name to it.startEpochMs },
            entries.filter { it.protected }.map { it.name }.toSet(),
            cutoffMs,
        ).toSet()
        var freed = 0L
        for (entry in entries) {
            if (entry.name !in expired) continue
            if (delete(entry.name)) freed += entry.sizeBytes
        }
        return freed
    }

    /** Deletes the oldest unprotected clips until the total fits the budget. */
    fun enforceBudget(budgetBytes: Long): Long {
        val entries = list().sortedBy { it.startEpochMs }
        var remaining = entries.sumOf { it.sizeBytes }
        if (budgetBytes <= 0) return remaining
        for (entry in entries) {
            if (remaining <= budgetBytes) break
            if (entry.protected) continue
            if (delete(entry.name)) remaining -= entry.sizeBytes
        }
        return remaining
    }
}

/** New clips go to the first repository that accepts them. */
class RepoSet(private val repos: List<ClipRepository>) : ClipRepository {
    override val label: String get() = repos.joinToString(" + ") { it.label }

    // One unreadable repository (a revoked folder) must not hide the others.
    override fun list(): List<ClipEntry> = repos
        .flatMap { repo -> runCatching { repo.list() }.getOrDefault(emptyList()) }
        .sortedBy { it.startEpochMs }

    override fun save(clip: File, protected: Boolean): Boolean =
        repos.any { repo -> runCatching { repo.save(clip, protected) }.getOrDefault(false) }

    override fun delete(name: String): Boolean = repos.any { it.delete(name) }

    override fun clearProtection(name: String): Boolean =
        repos.any { it.clearProtection(name) }

    override fun freeBytes(): Long? =
        repos.mapNotNull { it.freeBytes() }.minOrNull()
}

object ClipDates {
    fun path(epochMs: Long): String =
        SimpleDateFormat("yyyy/MM/dd", Locale.US).format(Date(epochMs))
}

class LocalClipRepo(private val context: Context) : ClipRepository {
    override val label: String = "App storage"

    private val root: File?
        get() = ClipStore.clipDir(context)

    override fun list(): List<ClipEntry> {
        val dir = root ?: return emptyList()
        val entries = mutableListOf<ClipEntry>()
        dir.walkTopDown().maxDepth(5).forEach { file ->
            if (!file.isFile || !ClipStore.clipName.matches(file.name)) {
                return@forEach
            }
            val uri = runCatching {
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    file,
                )
            }.getOrNull() ?: return@forEach
            entries.add(
                ClipEntry(
                    name = file.name,
                    uri = uri,
                    sizeBytes = file.length(),
                    startEpochMs = startMs(file.name),
                    protected = isProtected(file),
                    repo = this,
                ),
            )
        }
        return entries
    }

    override fun save(clip: File, protected: Boolean): Boolean {
        val dir = root?.let { File(it, ClipDates.path(startMs(clip.name))) }
            ?: return false
        if (!dir.exists() && !dir.mkdirs()) return false
        val target = File(dir, clip.name)
        if (target.exists()) return false
        val moved = clip.renameTo(target) || runCatching {
            clip.inputStream().use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
            clip.delete()
            true
        }.getOrDefault(false)
        if (!moved) {
            target.delete()
            return false
        }
        val marked = protected &&
            runCatching { File(dir, clip.name + ".protected").createNewFile() }
                .getOrDefault(false)
        // Keep the old marker when the new one could not be written, so a
        // crash clip never becomes deletable through a copy failure.
        if (!protected || marked) {
            File(clip.parentFile, clip.name + ".protected").delete()
        }
        return true
    }

    override fun delete(name: String): Boolean {
        val clip = find(name) ?: return false
        val deleted = clip.delete()
        if (deleted) File(clip.parentFile, clip.name + ".protected").delete()
        return deleted
    }

    override fun clearProtection(name: String): Boolean {
        val clip = find(name) ?: return false
        val marker = File(clip.parentFile, clip.name + ".protected")
        return marker.delete() || !marker.exists()
    }

    override fun freeBytes(): Long? =
        runCatching { root?.usableSpace?.takeIf { it > 0 } }.getOrNull()

    private fun find(name: String): File? {
        if (!ClipStore.clipName.matches(name)) return null
        val dir = root ?: return null
        return dir.walkTopDown().maxDepth(5)
            .firstOrNull { it.isFile && it.name == name }
    }

    private fun isProtected(clip: File): Boolean =
        File(clip.parentFile, clip.name + ".protected").exists()
}

class SafClipRepo(
    private val context: Context,
    treeUri: Uri,
) : ClipRepository {
    private val root: DocumentFile = DocumentFile.fromTreeUri(context, treeUri)
        ?.takeIf { it.isDirectory && it.canWrite() }
        ?: throw IllegalStateException("Folder is not writable")

    override val label: String = root.name ?: "Folder"

    override fun list(): List<ClipEntry> {
        val entries = mutableListOf<ClipEntry>()
        walk(root, entries, 0)
        return entries
    }

    private fun walk(dir: DocumentFile, out: MutableList<ClipEntry>, depth: Int) {
        if (depth > 4) return
        for (doc in dir.listFiles()) {
            val name = doc.name ?: continue
            if (doc.isDirectory) {
                walk(doc, out, depth + 1)
                continue
            }
            if (!ClipStore.clipName.matches(name)) continue
            out.add(
                ClipEntry(
                    name = name,
                    uri = doc.uri,
                    sizeBytes = doc.length(),
                    startEpochMs = startMs(name),
                    protected = dir.findFile("$name.protected")?.exists() == true,
                    repo = this,
                ),
            )
        }
    }

    override fun save(clip: File, protected: Boolean): Boolean {
        val day = dayFolder(startMs(clip.name)) ?: return false
        if (day.findFile(clip.name) != null) return false
        val target = day.createFile("video/mp4", clip.name) ?: return false
        val copied = runCatching {
            context.contentResolver.openOutputStream(target.uri, "wb")
                ?.use { output ->
                    clip.inputStream().use { input -> input.copyTo(output) }
                } != null
        }.getOrDefault(false)
        if (!copied) {
            runCatching { target.delete() }
            return false
        }
        val marked = protected && runCatching {
            day.createFile("application/octet-stream", clip.name + ".protected")
        }.getOrNull() != null
        clip.delete()
        if (!protected || marked) {
            File(clip.parentFile, clip.name + ".protected").delete()
        }
        return true
    }

    override fun delete(name: String): Boolean {
        val found = find(name) ?: return false
        val (parent, doc) = found
        val marker = parent.findFile("$name.protected")
        val deleted = runCatching { doc.delete() }.getOrDefault(false)
        if (deleted) runCatching { marker?.delete() }
        return deleted
    }

    override fun clearProtection(name: String): Boolean {
        val (parent, _) = find(name) ?: return false
        val marker = parent.findFile("$name.protected") ?: return true
        return runCatching { marker.delete() }.getOrDefault(false)
    }

    override fun freeBytes(): Long? =
        runCatching {
            context.getExternalFilesDir(null)?.usableSpace?.takeIf { it > 0 }
        }.getOrNull()

    private fun find(name: String): Pair<DocumentFile, DocumentFile>? {
        if (!ClipStore.clipName.matches(name)) return null
        return search(root, name, 0)
    }

    private fun search(
        dir: DocumentFile,
        name: String,
        depth: Int,
    ): Pair<DocumentFile, DocumentFile>? {
        if (depth > 4) return null
        for (doc in dir.listFiles()) {
            if (doc.isDirectory) {
                search(doc, name, depth + 1)?.let { return it }
            } else if (doc.name == name) {
                return dir to doc
            }
        }
        return null
    }

    private fun dayFolder(epochMs: Long): DocumentFile? {
        var dir = root
        for (part in ClipDates.path(epochMs).split("/")) {
            dir = dir.findFile(part) ?: dir.createDirectory(part) ?: return null
        }
        return dir
    }
}

object ClipRepos {
    private const val PREFS = "reason"
    private const val KEY_URI = "storageTreeUri"
    private const val KEY_LABEL = "storageLabel"

    fun create(context: Context): RepoSet {
        val local = LocalClipRepo(context)
        val stored = storedFolder(context)
        val saf = stored?.let { (uri, _) ->
            runCatching { SafClipRepo(context, Uri.parse(uri)) }.getOrNull()
        }
        return RepoSet(listOfNotNull(saf, local))
    }

    fun storedFolder(context: Context): Pair<String, String>? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val uri = prefs.getString(KEY_URI, null) ?: return null
        val label = prefs.getString(KEY_LABEL, null) ?: "Folder"
        return uri to label
    }

    fun storeFolder(context: Context, uri: String?, label: String?) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().apply {
            if (uri == null) {
                remove(KEY_URI)
                remove(KEY_LABEL)
            } else {
                putString(KEY_URI, uri)
                putString(KEY_LABEL, label)
            }
        }.apply()
    }
}

private fun startMs(name: String): Long =
    name.removeSuffix(".mp4").toLongOrNull() ?: 0L
