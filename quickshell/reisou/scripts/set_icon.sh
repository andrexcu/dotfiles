#!/usr/bin/env bash
# Kill existing Quickshell to avoid duplicates
pkill quickshell 2>/dev/null

# Launch Quickshell with Breeze-Dark icon theme
XDG_ICON_THEME=Breeze-Dark quickshell