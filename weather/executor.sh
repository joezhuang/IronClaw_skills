#!/bin/bash
# Pass the argument (the city) to the weather service
curl -s "wttr.in/$1?format=3"