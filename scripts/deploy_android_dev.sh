#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.sommersprossen.app.dev"
APK_PATH="build/app/outputs/flutter-apk/app-dev-debug.apk"
VERSION_FILE=".deploy_version_dev"
FINGERPRINT_FILE=".deploy_fingerprint_dev"

if command -v adb >/dev/null 2>&1; then
  ADB_BIN="$(command -v adb)"
else
  ADB_BIN="$HOME/Library/Android/sdk/platform-tools/adb"
fi

if [[ ! -x "$ADB_BIN" ]]; then
  echo "adb not found. Expected at: $ADB_BIN"
  exit 1
fi

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$($ADB_BIN devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No Android emulator detected. Start one and retry."
  exit 1
fi

echo "Using device: $DEVICE_ID"

if [[ -f "$VERSION_FILE" ]]; then
  CURRENT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
else
  CURRENT_VERSION="1"
fi

if [[ ! "$CURRENT_VERSION" =~ ^[0-9]+$ ]]; then
  echo "Invalid version in $VERSION_FILE: $CURRENT_VERSION"
  exit 1
fi

declare -a SOURCE_FILES=()

if [[ -d "lib" ]]; then
  while IFS= read -r -d '' f; do
    SOURCE_FILES+=("$f")
  done < <(find lib -type f -print0)
fi

if [[ -d "android" ]]; then
  while IFS= read -r -d '' f; do
    SOURCE_FILES+=("$f")
  done < <(find android -type f -print0)
fi

if [[ -f "pubspec.yaml" ]]; then
  SOURCE_FILES+=("pubspec.yaml")
fi

if [[ ${#SOURCE_FILES[@]} -eq 0 ]]; then
  SOURCE_FINGERPRINT="no-source-files"
else
  SORTED_FILES="$(printf '%s\n' "${SOURCE_FILES[@]}" | sort)"
  SOURCE_FINGERPRINT="$({
    while IFS= read -r file; do
      shasum "$file"
    done <<< "$SORTED_FILES"
  } | shasum | awk '{print $1}')"
fi

LAST_FINGERPRINT=""
if [[ -f "$FINGERPRINT_FILE" ]]; then
  LAST_FINGERPRINT="$(tr -d '[:space:]' < "$FINGERPRINT_FILE")"
fi

if [[ "$SOURCE_FINGERPRINT" != "$LAST_FINGERPRINT" ]]; then
  NEXT_VERSION="$((CURRENT_VERSION + 1))"
  echo "$NEXT_VERSION" > "$VERSION_FILE"
  echo "$SOURCE_FINGERPRINT" > "$FINGERPRINT_FILE"
  VERSION_BUMP_MSG="changed sources detected -> bumped"
else
  NEXT_VERSION="$CURRENT_VERSION"
  VERSION_BUMP_MSG="no source changes -> kept"
fi

echo "Deploy version: $NEXT_VERSION ($VERSION_BUMP_MSG)"
echo "Building dev debug APK..."
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev --dart-define=APP_DEPLOY_VERSION="$NEXT_VERSION"

echo "Removing old app (if present)..."
"$ADB_BIN" -s "$DEVICE_ID" uninstall "$APP_ID" >/dev/null 2>&1 || true

echo "Installing APK..."
"$ADB_BIN" -s "$DEVICE_ID" install -r "$APK_PATH"

echo "Launching app..."
"$ADB_BIN" -s "$DEVICE_ID" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null

echo "Done. App is running on $DEVICE_ID"