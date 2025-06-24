#!/bin/bash
# Launch all available Android emulators for testing
# Usage: ./scripts/emulators/launch_all_emulators.sh [--headless] [--wipe-data]

# Enable strict error handling
set -euo pipefail

# Configuration
EMULATOR_NAMES=(
  "Pixel_4_API_31"
  "Pixel_6_PRO_API_33"
  "Nexus_5_API_29"
)
AVD_MANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
EMULATOR="$ANDROID_HOME/emulator/emulator"
ADB="$ANDROID_HOME/platform-tools/adb"
MAX_LAUNCH_TIME=300  # 5 minutes in seconds
CHECK_INTERVAL=5     # seconds between checks

# Parse command line arguments
HEADLESS=false
WIPE_DATA=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --headless)
      HEADLESS=true
      shift
      ;;
    --wipe-data)
      WIPE_DATA=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: $0 [--headless] [--wipe-data]"
      exit 1
      ;;
  esac
done

# Verify Android tools are available
verify_tools() {
  if [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ ANDROID_HOME not set or invalid"
    exit 1
  fi

  for tool in "$AVD_MANAGER" "$EMULATOR" "$ADB"; do
    if [ ! -f "$tool" ]; then
      echo "❌ Tool not found: $tool"
      exit 1
    fi
  done
}

# Check if emulator exists
emulator_exists() {
  "$AVD_MANAGER" list avd | grep -q "$1"
}

# Launch a single emulator
launch_emulator() {
  local emulator_name=$1
  local pid_file="/tmp/emulator_${emulator_name}.pid"

  if ! emulator_exists "$emulator_name"; then
    echo "⚠️ Emulator $emulator_name not found, skipping"
    return
  fi

  echo "🚀 Launching $emulator_name..."

  local args=(
    "-avd" "$emulator_name"
    "-no-snapshot-save"
    "-no-boot-anim"
    "-no-audio"
  )

  if [ "$HEADLESS" = true ]; then
    args+=("-no-window")
  fi

  if [ "$WIPE_DATA" = true ]; then
    args+=("-wipe-data")
  fi

  # Start emulator in background
  "$EMULATOR" "${args[@]}" &> "${emulator_name}.log" &
  echo $! > "$pid_file"

  # Wait for boot completion
  wait_for_boot "$emulator_name"
}

# Wait until emulator is fully booted
wait_for_boot() {
  local emulator_name=$1
  local start_time=$(date +%s)
  local timeout=$MAX_LAUNCH_TIME
  local elapsed=0

  echo "⏳ Waiting for $emulator_name to boot..."

  while [ $elapsed -lt $timeout ]; do
    # Check if device is online
    if "$ADB" devices | grep -q "${emulator_name}.*device"; then
      # Check if boot completed
      if "$ADB" -s "$emulator_name" shell getprop sys.boot_completed | grep -q "1"; then
        echo "✅ $emulator_name is ready"
        return
      fi
    fi

    sleep $CHECK_INTERVAL
    elapsed=$(($(date +%s) - start_time))
  done

  echo "❌ Timeout waiting for $emulator_name to boot"
  kill_emulator "$emulator_name"
  exit 1
}

# Kill a running emulator
kill_emulator() {
  local emulator_name=$1
  local pid_file="/tmp/emulator_${emulator_name}.pid"

  if [ -f "$pid_file" ]; then
    echo "🛑 Stopping $emulator_name..."
    kill -9 "$(cat "$pid_file")" 2>/dev/null || true
    rm -f "$pid_file"
  fi
}

# Cleanup function
cleanup() {
  echo "🧹 Cleaning up..."
  for emulator in "${EMULATOR_NAMES[@]}"; do
    kill_emulator "$emulator"
  done
}

# Main execution
main() {
  verify_tools

  # Register cleanup on script exit
  trap cleanup EXIT

  # Launch all emulators in parallel
  for emulator in "${EMULATOR_NAMES[@]}"; do
    launch_emulator "$emulator" &
  done

  # Wait for all emulators to launch
  wait

  echo "🎉 All emulators launched successfully!"
  echo "📋 Running devices:"
  "$ADB" devices -l

  # Keep script running until Ctrl-C
  while true; do sleep 60; done
}

main