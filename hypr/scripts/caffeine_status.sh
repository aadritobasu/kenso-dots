#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
    echo false
else
    echo true
fi
