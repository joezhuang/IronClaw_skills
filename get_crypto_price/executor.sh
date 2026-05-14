#!/bin/bash
VAR1=$(echo "$1" | jq -r '.coin_id | ascii_downcase')
VAR2=$(echo "$1" | jq -r '.vs_currency | ascii_downcase')
curl -s "https://api.coingecko.com/api/v3/simple/price?ids=$VAR1&vs_currencies=$VAR2" | jq -r --arg v1 "$VAR1" --arg v2 "$VAR2" '.[$v1][$v2]'