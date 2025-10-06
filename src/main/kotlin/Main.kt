import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.strava.api.v3.api.ActivitiesApi
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import java.nio.file.Files
import kotlin.io.path.Path

fun main() {

    val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        encodeDefaults = true
    }

    fun okHttp(accessTokenProvider: () -> String) = OkHttpClient.Builder()
        .addInterceptor(Interceptor { chain ->
            val req = chain.request().newBuilder()
                .header("Authorization", "Bearer ${accessTokenProvider()}")
                .build()
            chain.proceed(req)
        })
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BASIC
        })
        .build()

    fun retrofitApi(accessTokenProvider: () -> String): Retrofit =
        Retrofit.Builder()
            .baseUrl("https://www.strava.com/api/v3/")
            .client(okHttp(accessTokenProvider))
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()

    fun retrofitAuth(): Retrofit =
        Retrofit.Builder()
            .baseUrl("https://www.strava.com/")
            .client(OkHttpClient())
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()

    val accessData = json.decodeFromString<AccessData>(
        Files.readString(Path("access.json"))
    )

    val token = runBlocking {
        retrofitAuth().create(StravaAuthApi::class.java).exchangeToken(
            accessData.client_id,
            accessData.client_secret,
            accessData.code
        )
    }

    val activitiesApi = retrofitApi { token.access_token }.create(ActivitiesApi::class.java)

    runBlocking {
        val listResponse = activitiesApi.getLoggedInAthleteActivities(perPage = 5)
        listResponse.body()!!.forEach {
            println("${it.name} (${it.type})")
        }
    }
}