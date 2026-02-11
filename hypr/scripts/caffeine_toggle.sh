#!/usr/bin/env bash

STATE_FILE="/tmp/hypr_caffeine"

if [ -f "$STATE_FILE" ]; then
    hyprctl idle uninhibit
    rm "$STATE_FILE"
    notify-send "Caffeine" "Disabled 😴"
else
    hyprctl idle inhibit
    touch "$STATE_FILE"
    notify-send "Caffeine" "Enabled ☕"
fi
