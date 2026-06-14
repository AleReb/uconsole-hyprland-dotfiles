#!/bin/bash

. "$HOME/.config/uconsole/theme.env" 2>/dev/null || true

STATE=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
PERCENT=$(printf '%s\n' "$STATE" | awk '{printf "%d", $2*100}')
MUTED=$(printf '%s\n' "$STATE" | grep -c "MUTED")

if [ "$MUTED" -gt 0 ]; then
  PERCENT=0
  TITLE="Mute"
else
  TITLE="Vol"
fi

BG="#${UCONSOLE_BG:-1f2328}ee"
FG="#${UCONSOLE_FG:-f8fafc}"
HL="#${UCONSOLE_ACCENT1:-93cee9}"

dunstify \
  -h string:x-dunst-stack-tag:osd \
  -h string:bgcolor:"$BG" \
  -h string:fgcolor:"$FG" \
  -h string:hlcolor:"$HL" \
  -h int:value:"$PERCENT" \
  -t 1200 \
  "$TITLE" "$PERCENT%"
