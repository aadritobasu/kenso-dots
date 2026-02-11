#!/usr/bin/env bash

STATE_FILE="/tmp/hypr_caffeine"

if [ -f "$STATE_FILE" ]; then
    # ----- Disable caffeine → start hypridle -----

    if ! pgrep -x hypridle >/dev/null; then
        hypridle &
    fi

    rm "$STATE_FILE"
    notify-send "☕ Caffeine Mode" "Disabled"

else
    # ----- Enable caffeine → stop hypridle -----

    pkill -x hypridle

    touch "$STATE_FILE"
    notify-send "☕ Caffeine Mode" "Enabled"
fi
