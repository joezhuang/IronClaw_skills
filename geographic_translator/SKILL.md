# Geographic Translator Skill

This skill takes a suburb name and retrieves its exact latitude and longitude using a web-based geographic search (powered by Nominatim/OpenStreetMap).

## Requirements
- macOS with Python 3 installed.
- Internet connection for search capability.

## Installation
No external libraries are required as it uses the built-in `urllib` library. 

## Usage
The skill accepts a single JSON argument containing the `suburb_name`.