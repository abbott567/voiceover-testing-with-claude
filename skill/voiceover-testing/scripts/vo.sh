#!/usr/bin/env bash

# A wrapper around VoiceOver's AppleScript dictionary
#
#   vo.sh start                   turn VoiceOver on, if it isn't already
#   vo.sh stop                    turn VoiceOver off
#   vo.sh first                   move the VoiceOver cursor to the first item inside the web page
#   vo.sh next                    move the VoiceOver cursor right
#   vo.sh prev                    move the VoiceOver cursor left
#   vo.sh activate                press the item in the VoiceOver cursor, like VO-Space
#   vo.sh find <name> [text]...   move through the page from the top until an announcement contains the name as whole words and the rest anywhere, for example: find "Sign in" button
#   vo.sh last                    print everything VoiceOver said after the last command runs
#
# Every command that moves the cursor or presses something prints what VoiceOver announced as a result, so you can log that directly, or run `vo.sh last` afterwards to see it again.
set -euo pipefail

LAST_FILE="${TMPDIR:-/tmp}/vo-sh-last-announcement"

vo() { osascript -e "tell application \"VoiceOver\" to $1"; }

# Collects everything VoiceOver says over the next couple of seconds and joins it with commas. VoiceOver announces an item in chunks, and its "last phrase" only ever holds the latest chunk, so only reading once straight after a move can miss most of it.
capture() {
  local before=$1 phrase previous='' out='' quiet=0
  for _ in $(seq 1 12); do
    sleep 0.1
    phrase=$(vo 'return content of last phrase' 2>/dev/null || true)
    phrase=${phrase//$'\n'/ }
    if [[ -n "$phrase" && "$phrase" != "$previous" && ( -n "$out" || "$phrase" != "$before" ) ]]; then
      out+="${out:+, }$phrase"
      previous=$phrase
      quiet=0
    elif [[ -n "$out" ]]; then
      quiet=$((quiet + 1))
      if [[ $quiet -ge 4 ]]; then break; fi
    fi
  done
  printf '%s\n' "$out" > "$LAST_FILE"
  printf '%s\n' "$out"
}

# Runs one VoiceOver command, then prints what VoiceOver said about it
act() {
  local before
  before=$(vo 'return content of last phrase' 2>/dev/null || true)
  vo "$1"
  capture "$before"
}

# Puts the VoiceOver cursor on the first item inside the web page. It starts from the window's first item, which means walking past the toolbar to the "web content" area and interacting with it. If no web content area turns up, the cursor was already inside the page, so just go back to the top.
enter_web_content() {
  local phrase
  vo 'tell vo cursor to move to first item'
  sleep 0.3
  for _ in $(seq 1 12); do
    phrase=$(vo 'return content of last phrase' 2>/dev/null || true)
    if [[ "$phrase" == *"web content"* ]]; then
      act 'tell vo cursor to move into item'
      return 0
    fi
    vo 'tell vo cursor to move right'
    sleep 0.3
  done
  act 'tell vo cursor to move to first item'
}

# True when the announcement contains the name as whole words and every other needle anywhere, ignoring case. Whole words, so "Email address" matches "Email address email field" but not "Enter your email addresses".
phrase_has() {
  local phrase=$1 name=$2 needle escaped regex
  shift 2
  shopt -s nocasematch
  [[ -n "$phrase" ]] || return 1
  for needle in "$@"; do
    [[ "$phrase" == *"$needle"* ]] || return 1
  done
  escaped=$(printf '%s' "$name" | sed 's/[][\.*^$+?(){}|\\]/\\&/g')
  regex="(^|[^[:alnum:]])${escaped}($|[^[:alnum:]])"
  [[ "$phrase" =~ $regex ]]
}

case "${1:-}" in
  start)
    # Only start VoiceOver if it isn't already running, then wait for it to announce itself
    if ! pgrep -xq VoiceOver; then
      open -a VoiceOver
      until vo 'return content of last phrase' 2>/dev/null | grep -q 'VoiceOver is on'; do
        sleep 0.1
      done
    fi ;;
  stop)     vo 'quit' ;;
  first)    enter_web_content ;;
  next)     act 'tell vo cursor to move right' ;;
  prev)     act 'tell vo cursor to move left' ;;
  activate) act 'tell vo cursor to perform action' ;;
  last)     cat "$LAST_FILE" 2>/dev/null || vo 'return content of last phrase' ;;
  find)
    shift
    if [[ $# -eq 0 ]]; then
      echo 'usage: vo.sh find <name> [text]..., e.g. vo.sh find "Sign in" button' >&2
      exit 1
    fi
    announcement=$(enter_web_content)
    empties=0
    for _ in $(seq 1 80); do
      if phrase_has "$announcement" "$@"; then
        echo "$announcement"
        exit 0
      fi
      # VoiceOver's hint about leaving the web area, or nothing new announced twice in a row, means the cursor has stopped moving
      if [[ "$announcement" == *"exit this web area"* ]]; then break; fi
      if [[ -z "$announcement" ]]; then
        empties=$((empties + 1))
        if [[ $empties -ge 2 ]]; then break; fi
      else
        empties=0
      fi
      announcement=$(act 'tell vo cursor to move right')
    done
    echo "Couldn't find an item announced as: $*" >&2
    exit 1 ;;
  *) echo "usage: vo.sh start|stop|first|next|prev|activate|find|last" >&2; exit 1 ;;
esac
