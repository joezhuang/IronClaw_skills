#!/bin/bash

# Extract the element name and force it to lowercase using .lower()
ELEMENT=$(python3 -c "import sys, json; print(json.loads(sys.argv[1]).get('element_name', '').lower())" "$1")

# Failsafe: Don't run if the extracted name is empty
if [ -z "$ELEMENT" ]; then
    echo "Error: Element name is empty or not provided."
    exit 1
fi

script=$(cat <<EOF
tell application "System Events"
    tell process "Dock"
        tell list 1
            set targetName to "$ELEMENT"
            set allElements to UI elements
            set foundElem to missing value
            
            -- Loop through all Dock elements to find a partial match
            repeat with elem in allElements
                set elemName to name of elem
                if elemName is not missing value then
                    -- 'contains' does a case-insensitive partial match
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
    echo "Error: Could not find any element containing '$ELEMENT' in the Dock."
fi