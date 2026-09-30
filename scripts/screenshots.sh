#!/usr/bin/env bash
# Builds My Day, runs it in iPhone simulators and saves a screenshot of every
# main screen into ./screenshots (or the folder given as the first argument).
#
#   ./scripts/screenshots.sh
#   SCREENSHOT_DEVICES="iPhone 17 Pro" ./scripts/screenshots.sh out
#
# SAMPLE_ROUTES="todos-add" also prints where the app's main thread is busy
# when that screen is captured (useful when a screen does not appear).
set -euo pipefail

BUNDLE_ID="com.regina3579.myday"
OUT="${1:-screenshots}"
# todos-hearts ticks a to-do, todos-alldone ticks all of them, priority-hearts ticks the
# day's first priority, priority-alldone the rest, priority-empty deletes them all, and
# journal-proud changes the day's page to a mood picked with ＋, so they come last.
ROUTES=(home quickadd menu todos todos-add todos-photo todos-voice todos-templates priority journal journal-page calendar insights settings newtask newjournal todos-hearts todos-alldone todos-confetti priority-hearts priority-alldone priority-empty calendar-tomorrow journal-pages journal-templates journal-feelings journal-photos journal-trash journal-filter journal-new journal-middle journal-bottom journal-proud journal-moods journal-voice settings-sounds todos-template-edit journal-lock-pattern journal-lock-passcode settings-lock settings-lock-choose todos-voice-shopping todos-voice-tip todos-quote-tip todos-template-move journal-opening)
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

  # The app writes this file once its screen is up (see DebugLaunchRoute.markReady), so a
  # slow start on a busy machine does not end up as a picture of the launch screen.
  marker="$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data)/Library/Caches/screenshot-ready"
  wait_seconds=10
  n=1
  for route in "${ROUTES[@]}"; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    rm -f "$marker"
    xcrun simctl launch "$udid" "$BUNDLE_ID" -screenshotRoute "$route" >/dev/null
    for _ in $(seq 1 90); do
      [ -f "$marker" ] && break
      sleep 0.5
    done
    [ -f "$marker" ] || echo "  $route: the app did not say it was ready within 45 seconds"
    # The first screen that shows the keyboard also starts the simulator's
    # keyboard services, which takes several seconds.
    [ "$route" = "todos-add" ] && wait_seconds=15
    sleep "$wait_seconds"
    wait_seconds=10
    xcrun simctl io "$udid" screenshot "$OUT/${slug}-$(printf '%02d' "$n")-${route}.png" >/dev/null
    pid="$(pgrep -f "/MyDay.app/MyDay" | head -1 || true)"
    [ -z "$pid" ] && echo "  $route: MyDay is not running"
    if [ -n "$pid" ] && [[ " ${SAMPLE_ROUTES:-} " == *" $route "* ]]; then
      report="$OUT/sample-${slug}-${route}.txt"
      sample "$pid" 2 -file "$report" >/dev/null 2>&1 || true
      echo "---- $route: busiest code on the main thread ----"
      sed -n '/Sort by top of stack/,/Binary Images/p' "$report" | head -40 || true
      echo "---- $route: main thread call graph ----"
      sed -n '/Call graph:/,/Total number in stack/p' "$report" | grep -v "^ *$" | head -60 | cut -c1-220 || true
      echo "---- $route: app log ----"
      xcrun simctl spawn "$udid" log show --last 30s --style compact \
        --predicate 'process == "MyDay"' 2>/dev/null | grep -v "^Timestamp" | tail -80 | cut -c1-300 || true
      # A second look, to tell a slow screen from one that never appears.
      sleep 12
      xcrun simctl io "$udid" screenshot "$OUT/${slug}-$(printf '%02d' "$n")-${route}-later.png" >/dev/null
    fi
    n=$((n + 1))
  done
  xcrun simctl shutdown "$udid" || true
done

ls -1 "$OUT"

crashes="$(ls -t ~/Library/Logs/DiagnosticReports 2>/dev/null | grep -i myday | head -3 || true)"
for report in $crashes; do
  echo "---- crash report: $report ----"
  head -120 ~/Library/Logs/DiagnosticReports/"$report" || true
done
