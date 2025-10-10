#!/bin/bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required. Install it (e.g., 'brew install jq') and retry."
  exit 1
fi

# --- CONFIG ------------------------------------------------------------
GRADLE_FILE="generated/kotlin/build.gradle"
CONFIG_FILE='config.json'
ARTIFACT_ID=$(jq -r '.artifactId // empty' "$CONFIG_FILE")
DEPENDENCY='implementation "com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:1.0.0"'
# ----------------------------------------------------------------------

echo "🧹 Cleaning up old generated code..."
rm -rf generated

echo "🛠  Generating Kotlin client code..."
openapi-generator generate \
  -i https://developers.strava.com/swagger/swagger.json \
  -g kotlin \
  -o generated/kotlin \
  -c config.json \
  --skip-validate-spec \
  --additional-properties=library=jvm-retrofit2,useCoroutines=true,serializationLibrary=kotlinx_serialization,dateLibrary=kotlinx-datetime

# --- Copy custom files -----------------------------------------------
echo "📋 Copying custom files for auth flow..."
mkdir -p generated/kotlin/src/main/kotlin/org/vandeseer/kstrava/auth
cp -r -v src/main/kotlin/org/vandeseer/kstrava/auth/* generated/kotlin/src/main/kotlin/org/vandeseer/kstrava/auth

# --- Update Gradle file to include maven publish plugin ---------------
if [[ -f "$GRADLE_FILE" ]]; then
  cat >> $GRADLE_FILE <<KOTLIN

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

# --- Update Gradle file to include dependency ----------------------------
## Note: This is a extremely hacky, but it works for now (at least on macOS)
## For Linux (GNU sed), remove the '' after -i
echo "Adding dependency"
sed -i '' "30,\${
/^[[:space:]]*dependencies[[:space:]]*{/a\\
  $DEPENDENCY
}" "$GRADLE_FILE" && echo "Dependency added."
# ----------------------------------------------------------------------

chmod +x generated/kotlin/gradlew
cd generated/kotlin

./gradlew check assemble
./gradlew build
./gradlew publishToMavenLocal

echo "🎉 Done!"