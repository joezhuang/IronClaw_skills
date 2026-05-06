#!/bin/bash

# Extract the element name and force it to lowercase
ELEMENT=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('element_name', '').lower())" "$1")

if [ -z "$ELEMENT" ]; then
    echo "Error: Element name is empty."
    exit 1
fi

# 1. Check if the Dock is currently auto-hidden and save that state
IS_HIDDEN=$(osascript -e 'tell application "System Events" to get autohide of dock preferences')

# 2. If it is hidden, force it to show up and wait for the animation
if [ "$IS_HIDDEN" = "true" ]; then
    osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
    sleep 1 # Give the Dock a moment to slide up
fi

# 3. Your core AppleScript logic
script=$(cat <<EOF
tell application "System Events"
    tell process "Dock"
        tell list 1
            set targetName to "$ELEMENT"
            set allElements to UI elements
            set foundElem to missing value
            
            repeat with elem in allElements
                set elemName to name of elem
                if elemName is not missing value then
                    if elemName contains targetName then
                        set foundElem to elem
                        exit repeat
                    end if
                end if
            end repeat
            
            if foundElem is missing value then
                error "Not found"
            end if
            
            set pos to position of foundElem
            set sz to size of foundElem
            
            set centerX to (item 1 of pos) + ((item 1 of sz) / 2)
            set centerY to (item 2 of pos) + ((item 2 of sz) / 2)
            
            return (centerX div 1 as text) & "," & (centerY div 1 as text)
        end tell
    end tell
end tell
EOF
)

result=$(osascript -e "$script" 2>/dev/null)

# 4. Output the result
if [ $? -eq 0 ]; then
    echo "COORDS: $result"
else
    echo "Error: Could not find any element containing '$ELEMENT' in the Dock."
fi