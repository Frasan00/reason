package com.example.reason

/** Decides what "destroy after" removes. Pure, so the rule can be tested. */
object RetentionPlan {
    /**
     * Names to delete, given each clip's start time. The newest clip always
     * survives: a retention shorter than a segment would otherwise delete the
     * clip that was just written, on every save.
     */
    fun expired(
        clips: List<Pair<String, Long>>,
        protectedNames: Set<String>,
        cutoffMs: Long,
    ): List<String> {
        if (cutoffMs <= 0) return emptyList()
        return clips
            .sortedBy { (_, start) -> start }
            .dropLast(1)
            .filter { (name, start) ->
                name !in protectedNames && start < cutoffMs
            }
            .map { (name, _) -> name }
    }
}
