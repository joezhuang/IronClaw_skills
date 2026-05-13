#!/bin/bash

# Uses lsof to find ESTABLISHED connections, ignores local network chatter, 
# and formats it cleanly to AppName -> RemoteIP. Grabs the top 8.
lsof -i -P -n | grep ESTABLISHED | grep -e "->" | \
grep -v -e '127.0.0.1' -e '192.168.' -e '10.0.' -e '::1' -e 'fe80:' | \
awk '{
    # Extract App Name ($1) and the Connection ($9)
    split($9, parts, "->");
    remote = parts[2];
    # Strip the port (the part after the last colon)
    sub(/:[0-9]+$/, "", remote);
    # Strip brackets from IPv6 addresses for a cleaner look
    gsub(/[\[\]]/, "", remote);
    print $1 " -> " remote
}' | head -n 8