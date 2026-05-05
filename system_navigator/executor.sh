#!/bin/bash
ELEMENT=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('element_name', ''))" "$1")

script=$(cat <<EOF
tell application "System Events"
    tell process "Dock"
        tell list 1
            set uiElement to UI element "$ELEMENT"
            set pos to position of uiElement
            set sz to size of uiElement
            
            -- Calculate Center and force to integer
            set centerX to (item 1 of pos) + ((item 1 of sz) / 2)
            set centerY to (item 2 of pos) + ((item 2 of sz) / 2)
            
            -- Force truncation to integer to ensure valid pixel coordinates
            return (centerX div 1 as text) & "," & (centerY div 1 as text)
        end tell
    end tell
end tell
EOF
)

result=$(osascript -e "$script" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "COORDS: $result"
else
    echo "Error: Could not find element '$ELEMENT' in the Dock."
fi