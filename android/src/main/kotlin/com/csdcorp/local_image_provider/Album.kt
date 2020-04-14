package com.csdcorp.local_image_provider

import android.net.Uri

/// Holds the basic Album information while it is being collected and de-duplicated
class Album(val title: String, val id: String, val contentUri: Uri ) {
    override fun hashCode(): Int {
        return id.hashCode()
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other?.javaClass != javaClass) return false

        other as Album
        return id == other.id
    }
}