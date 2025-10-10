package main

import com.strava.api.v3.api.ActivitiesApi
import org.vandeseer.kstrava.auth.exchangeTokenUsing
import kotlinx.coroutines.runBlocking
import org.vandeseer.kstrava.auth.retrofitApi
import org.vandeseer.kstrava.auth.retrofitAuth

fun main() {

    val token = exchangeTokenUsing(retrofitAuth())
    val activitiesApi = retrofitApi { token.access_token }.create(ActivitiesApi::class.java)

    runBlocking {
        val listResponse = activitiesApi.getLoggedInAthleteActivities(perPage = 5)
        listResponse.body()!!.forEach {
            println("${it.name} (${it.type})")
        }
    }
}