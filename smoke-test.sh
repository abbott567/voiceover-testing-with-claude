#!/usr/bin/env bash

# Proves your terminal can drive VoiceOver, before Claude gets involved.
#
# Open a web page in Safari and make sure VoiceOver is OFF before running this.
# The first loop waits for VoiceOver's default login greeting, which ends
# "VoiceOver is on". If you've changed the greeting in VoiceOver Utility,
# change the text below to match.
set -euo pipefail

if pgrep -xq VoiceOver; then
  echo "VoiceOver is already running. Turn it off and try again." >&2
  exit 1
fi

# A polling loop, waits for VoiceOver to be on
open -a VoiceOver
until osascript -e 'tell application "VoiceOver" to return content of last phrase' 2>/dev/null | grep -q 'VoiceOver is on'; do
  sleep 0.1
done

# Switches to Safari
osascript -e 'tell application "Safari" to activate'

# A polling loop, waits for Safari to be the active app
until osascript -e 'tell application "Safari" to return frontmost' | grep -q true; do
  sleep 0.1
done

# Moves the VoiceOver cursor to the first element
osascript -e 'tell application "VoiceOver" to tell vo cursor to move to first item'

# Moves the VoiceOver cursor to the right
osascript -e 'tell application "VoiceOver" to tell vo cursor to move right'

# Captures the last thing VoiceOver announced
osascript -e 'tell application "VoiceOver" to return content of last phrase'

# Turns VoiceOver off
osascript -e 'tell application "VoiceOver" to quit'
