#!/bin/bash
# Pass the argument (the IP address) to the ipinfo API
# We grep specific fields so we don't blow out the AI's context window
curl -s "ipinfo.io/$1/json" | grep -E '"(hostname|city|region|country|org)"'