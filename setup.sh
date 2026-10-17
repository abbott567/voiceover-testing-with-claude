#!/usr/bin/env bash

# One-off setup for this project. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")"

SDEF=/System/Library/CoreServices/VoiceOver.app/Contents/Resources/VoiceOver.sdef

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This only works on macOS, because it drives VoiceOver." >&2
  exit 1
fi

if [[ ! -f "$SDEF" ]]; then
  echo "Couldn't find the VoiceOver dictionary at $SDEF" >&2
  exit 1
fi

mkdir -p .claude/refs
cp "$SDEF" .claude/refs/voiceover.sdef
chmod +x .claude/scripts/vo.sh skill/voiceover-testing/scripts/vo.sh smoke-test.sh

echo "Copied this Mac's VoiceOver dictionary to .claude/refs/voiceover.sdef"
echo "Made the scripts executable"
echo
echo "Now do the manual steps in the README:"
echo "  1. VoiceOver Utility > General: allow VoiceOver to be controlled with AppleScript"
echo "  2. System Settings > Privacy & Security > Accessibility: add the app you run Claude Code from"
echo "  3. VoiceOver Utility > Web and Navigation: turn off page load announcements and cursor wrapping"
echo
echo "Then open a page in Safari and run ./smoke-test.sh to prove it works."
