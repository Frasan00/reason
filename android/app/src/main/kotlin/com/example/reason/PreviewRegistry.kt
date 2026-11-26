package com.example.reason

import androidx.camera.core.Preview

object PreviewRegistry {
    @Volatile
    var provider: Preview.SurfaceProvider? = null

    fun clear(provider: Preview.SurfaceProvider) {
        if (this.provider === provider) this.provider = null
    }
}
