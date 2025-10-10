package org.vandeseer.kstrava.auth

import kotlinx.serialization.Serializable

@Serializable
data class AccessData(
    val client_id: String,
    val client_secret: String,
    val code: String
)