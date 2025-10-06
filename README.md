# README

## TLDR

A simple, hacky script to generate and install a Strava API client 
library for Kotlin into your local Maven repo. Batteries included – 
a sample file shows a minimal working solution. 

(This stuff should at least work on Mac 😅)

## How To

To generate the API client, install OpenAPI Generator and jq, e.g. via Homebrew:
```
brew install openapi-generator jq
```

Then simply run:

```
./generate_and_install.sh
```

If everything works, you should be able to import the library in your IDE by its coordinates:
```
groupId: com.strava.api
artifactId: kstrava
version: 3.0.0
```

To run the sample app, set up a Strava API application to get your client ID and secret:
https://www.strava.com/settings/api

Then get the authorization code by visiting the following URL in your browser (replace `client_id` and `redirect_uri` as appropriate):
https://www.strava.com/oauth/authorize?client_id=12345&redirect_uri=http://localhost:8000&response_type=code&scope=profile:read_all,activity:read_all

Fill in `client_id`, `client_secret`, and `code` in `access.json`, then run `Main.kt`.

The file `Main.kt` shows a simple example of retrieving some of your own activities.