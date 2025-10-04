#!/bin/bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required. Install it (e.g., 'brew install jq') and retry."
  exit 1
fi

# --- CONFIG ------------------------------------------------------------
INFRA_FILE="generated/kotlin/src/main/kotlin/com/strava/api/v3/client/infrastructure/QuerySerialization.kt"
LATLNG_FILE="generated/kotlin/src/main/kotlin/com/strava/api/v3/model/LatLng.kt"
GRADLE_FILE="generated/kotlin/build.gradle"
CONFIG_FILE='config.json'
GROUP_ID=$(jq -r '.groupId // empty' "$CONFIG_FILE")
ARTIFACT_ID=$(jq -r '.artifactId // empty' "$CONFIG_FILE")
ARTIFACT_VERSION=$(jq -r '.artifactVersion // empty' "$CONFIG_FILE")
# ----------------------------------------------------------------------

# Remove old generated code
echo "🧹 Cleaning up old generated code..."
rm -r generated

# Generate Kotlin client code using Swagger Codegen
echo "🛠  Generating Kotlin client code..."
swagger-codegen generate \
  -i https://developers.strava.com/swagger/swagger.json \
  -l kotlin \
  -o generated/kotlin \
  -c config.json \
  -DdateLibrary=java8 \
  -Dlibrary=jvm-retrofit2


echo "🛠  Fixing Swagger Kotlin client issues..."
# --- 1) Ensure parseDateToQueryString helper exists -------------------
echo "→ Creating helper: $INFRA_FILE"
mkdir -p "$(dirname "$INFRA_FILE")"

cat > "$INFRA_FILE" <<'KOTLIN'
// Auto-generated helper for missing parseDateToQueryString
package io.swagger.client.infrastructure

import java.time.*
import java.time.format.DateTimeFormatter

/**
 * Minimal replacement for the helper expected by some Swagger Kotlin clients.
 * Converts various date/time types into ISO query string format.
 */
public fun parameterToString(value: Any?): String = when (value) {
    null -> ""
    is OffsetDateTime -> value.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
    is ZonedDateTime  -> value.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
    is LocalDateTime  -> value.format(DateTimeFormatter.ISO_DATE_TIME)
    is LocalDate      -> value.format(DateTimeFormatter.ISO_DATE)
    is Instant        -> DateTimeFormatter.ISO_INSTANT.format(value)
    is java.util.Date -> DateTimeFormatter.ISO_INSTANT.format(value.toInstant())
    else              -> value.toString()
}

public inline fun <reified T: Any> parseDateToQueryString(value : T): String {
    /*
    .replace("\"", "") converts the json object string to an actual string for the query parameter.
    The moshi or gson adapter allows a more generic solution instead of trying to use a native
    formatter. It also easily allows to provide a simple way to define a custom date format pattern
    inside a gson/moshi adapter.
    */
    return Serializer.moshi.adapter(T::class.java).toJson(value).replace("\"", "")
}
KOTLIN

echo "✅ Helper created"

# --- 2) Patch LatLng typealias if broken -------------------------------
if [[ -f "$LATLNG_FILE" ]]; then
  if grep -q 'typealias LatLng = kotlin\.Array<' "$LATLNG_FILE"; then
    echo "→ Patching LatLng typealias in $LATLNG_FILE"
    sed -i.bak 's/typealias LatLng = kotlin\.Array<.*>/typealias LatLng = kotlin.Array<Double>/' "$LATLNG_FILE"
    echo "✅ LatLng typealias fixed (Array<Double>)"
  else
    echo "ℹ️  LatLng typealias already fine or not found"
  fi
else
  echo "⚠️  LatLng file not found at $LATLNG_FILE (adjust path if needed)"
fi

# --- 3) Update Gradle file to include maven publish plugin ---------------
if [[ -f "$GRADLE_FILE" ]]; then
  cat >> $GRADLE_FILE <<KOTLIN

apply plugin: 'maven-publish'

group = '$GROUP_ID'
version = '$ARTIFACT_VERSION'

publishing {
  publications {
    maven(MavenPublication) {
      from components.java
      artifactId = '$ARTIFACT_ID'
    }
  }
}
KOTLIN
else
  echo "⚠️  Gradle file not found at $GRADLE_FILE (adjust path if needed)"
fi

echo "🏗  Building and publishing the Kotlin client to local Maven repository..."

cd generated/kotlin
gradle wrapper
./gradlew check assemble
./gradlew build
./gradlew publishToMavenLocal


echo "🎉 Done!"