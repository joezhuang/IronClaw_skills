#!/bin/bash
VAR1=$(echo "$1" | jq -r '.city_name | ascii_downcase')
VAR2=$(echo "$1" | jq -r '.currency | ascii_downcase')
curl -s "https://api.fuelprice.com/average?city=$VAR1&currency=$VAR2" | jq -r --arg v1 "$VAR1" --arg v2 "$VAR2" '{"city": $v1, "currency": $v2, "price": .["$v1"]["$v2"]}'