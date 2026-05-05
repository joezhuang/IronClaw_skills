#!/bin/bash

# The primary timezone command
LOCATION=$(defaults read /Library/Preferences/.GlobalPreferences.plist com.apple.preferences.timezone.selected_city 2>/dev/null | grep "Name" | cut -d'"' -f2)

# Fallback to local time if defaults read returns nothing
if [ -z "$LOCATION" ]; then
    LOCATION=$(readlink /etc/localtime | awk -F'/' '{print $(NF-1) "/" $NF}')
fi

# Print a sanitized output
printf "%s" "$LOCATION"