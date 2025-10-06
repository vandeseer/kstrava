import kotlinx.serialization.Serializable

@Serializable
data class TokenResponse(
  val token_type: String,
  val access_token: String,
  val expires_at: Long,
  val expires_in: Long,
  val refresh_token: String
)