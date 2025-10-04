# README

Mostly following instructions from Strava API docs:
https://developers.strava.com/docs/

To generate the API client, install swagger-codegen v2:
```
brew install swagger-codegen@2
```

Ensure you have Java 11 or 17 installed (not 21, which is not supported by swagger-codegen v2).
Don't use gradle > 8, which requires Java 21.

With SDKMAN, you can do:
```
sdk install gradle 8.14.3
sdk use java 11.0.27-zulu # Or any Java < 21 JDK
```

Then simply run:

```
./generate.sh
```

If everything works, you should be able to import the library in your IDE by its coordinates:
```
groupId: com.strava
artifactId: strava-api-client
version: 1.0.0
```

To run the sample app, set up a Strava API application to get your client ID and secret:
https://www.strava.com/settings/api