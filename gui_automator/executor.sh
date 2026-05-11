#!/bin/bash

# A simple Python one-liner to parse the JSON arguments passed by Go
ACTION=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('action', ''))" "$1")
X=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('x', ''))" "$1")
Y=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('y', ''))" "$1")
TEXT=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('text', ''))" "$1")

case "$ACTION" in
    "screenshot")
        # ⏱️ UI BUFFER: Wait 1 second just in case a transition is happening
        sleep 1

        # Capture screen silently (-x) without shadow to a temporary file
        FILE_PATH="/tmp/ironclaw_screen.jpg"
        screencapture -x "$FILE_PATH"
        
        # Get the Mac's screen resolution bounds
        BOUNDS=$(osascript -e 'tell application "Finder" to get bounds of window of desktop')
        
        # Output the triggers for the Go Relay
        echo "[IMAGE_READY:$FILE_PATH]"
        echo "SCREEN_RESOLUTION_BOUNDS: [$BOUNDS]"
        ;;
        
    "click")
        if [ -n "$X" ] && [ -n "$Y" ]; then
            /opt/homebrew/bin/cliclick c:$X,$Y

            # ⏱️ UI BUFFER: Force the Go Relay to wait for the Mac to open the app/menu
            sleep 2
            
            echo "Successfully clicked at X:$X, Y:$Y"
        else
            echo "Error: Missing X or Y coordinates for click action."
        fi
        ;;
        
    "type")
        if [ -n "$TEXT" ]; then
            SAFE_TEXT=$(echo "$TEXT" | sed 's/"/\\"/g')
            osascript -e "tell application \"System Events\" to keystroke \"$SAFE_TEXT\""
            
            SUBMIT=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('submit', 'false'))" "$1")
            
            if [ "$SUBMIT" == "true" ]; then
                # Press Enter
                osascript -e 'tell application "System Events" to key code 36'
                
                # Wait for the app (Ollama) to print its results
                sleep 2 
                
                # Automatically take the screenshot
                FILE_PATH="/tmp/ironclaw_screen.jpg"
                screencapture -x -t jpg -S "$FILE_PATH"
                BOUNDS=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | sed 's/[{}]//g' | sed 's/ //g')
                
                # Output the image tags for the Relay's generic vision interceptor
                echo "Successfully typed and submitted. Here is the resulting screen state:"
                echo "[IMAGE_READY:$FILE_PATH]"
                echo "SCREEN_RESOLUTION_BOUNDS: [$BOUNDS]"
            else
                echo "Successfully typed text."
            fi
        else
            echo "Error: Missing text."
        fi
        ;;
        
    *)
        echo "Error: Invalid action specified."
        ;;
esac