#!/usr/bin/env bash
# Builds My Day, runs it in iPhone simulators and saves a screenshot of every
# main screen into ./screenshots (or the folder given as the first argument).
#
#   ./scripts/screenshots.sh
#   SCREENSHOT_DEVICES="iPhone 17 Pro" ./scripts/screenshots.sh out
set -euo pipefail

BUNDLE_ID="com.regina3579.myday"
OUT="${1:-screenshots}"
ROUTES=(home quickadd menu todos priority journal calendar insights settings newtask newjournal)
IFS='|' read -r -a DEVICES <<< "${SCREENSHOT_DEVICES:-iPhone 17 Pro|iPhone 17 Pro Max|iPhone SE (3rd generation)}"
mkdir -p "$OUT"

# UDID of the device with this exact name on the newest iOS runtime ("" if none).
# With the name "*", any iPhone on the newest runtime.
find_device() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
wanted = sys.argv[1]
best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in runtime.split(".iOS-")[-1].split("-"))
    for device in devices:
        name = device["name"]
        if (wanted == "*" and name.startswith("iPhone")) or name == wanted:
            if best is None or version > best[0]:
                best = (version, device["udid"])
print(best[1] if best else "")
' "$1"
}

UDIDS=()
NAMES=()
for name in "${DEVICES[@]}"; do
  udid="$(find_device "$name")"
  if [[ -n "$udid" ]]; then
    UDIDS+=("$udid"); NAMES+=("$name")
  else
    echo "Simulator not available, skipping: $name"
  fi
done
if [[ ${#UDIDS[@]} -eq 0 ]]; then
  UDIDS+=("$(find_device "*")"); NAMES+=("iPhone")
fi

echo "Building for ${NAMES[0]} (${UDIDS[0]})"
xcodebuild build \
  -project MyDay.xcodeproj \
  -scheme MyDay \
  -configuration Debug \
  -destination "id=${UDIDS[0]}" \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO -quiet
APP="build/DerivedData/Build/Products/Debug-iphonesimulator/MyDay.app"

for i in "${!UDIDS[@]}"; do
  udid="${UDIDS[$i]}"
  slug="$(echo "${NAMES[$i]}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/-*$//')"
  echo "Capturing on ${NAMES[$i]}"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
  xcrun simctl install "$udid" "$APP"

  wait_seconds=12
  n=1
  for route in "${ROUTES[@]}"; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshotRoute "$route" >/dev/null
    sleep "$wait_seconds"
    wait_seconds=8
    xcrun simctl io "$udid" screenshot "$OUT/${slug}-$(printf '%02d' "$n")-${route}.png" >/dev/null
    n=$((n + 1))
  done
  xcrun simctl shutdown "$udid" || true
done

ls -1 "$OUT"
