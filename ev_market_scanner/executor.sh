# #!/bin/bash

# # Standard Python pathing for your IronClaw setup
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# VENV_PYTHON="$SCRIPT_DIR/../../.venv/bin/python"

# if [ -f "$VENV_PYTHON" ]; then
#     EXEC_CMD="$VENV_PYTHON"
# else
#     EXEC_CMD="python3"
# fi

# $EXEC_CMD - "$1" << 'EOF'
# import sys, json, urllib.request
# import xml.etree.ElementTree as ET

# try:
#     args = json.loads(sys.argv[1])
#     brands = args.get("target_brands", [])
    
#     if not brands:
#         print("Error: No target brands provided by the LLM.")
#         sys.exit(1)

#     # Convert to lowercase for easy matching
#     target_brands = [b.lower() for b in brands]
    
#     # Fetch live data from Australia's top EV news site (The Driven)
#     url = "https://thedriven.io/feed/"
#     req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (IronClaw Local Agent)'})
    
#     with urllib.request.urlopen(req) as response:
#         xml_data = response.read()
        
#     root = ET.fromstring(xml_data)
    
#     print("--- TYPE: MARKET SCAN ---")
#     print("STATUS: SUCCESS")
#     print(f"TARGETS: {', '.join(brands).upper()}")
#     print("RAW DATA:")
    
#     found_any = False
#     # Parse the RSS XML for recent articles
#     for item in root.findall('.//item'):
#         title = item.find('title').text
#         link = item.find('link').text
#         pub_date = item.find('pubDate').text
        
#         # Check if any target brand is mentioned in the headline
#         for brand in target_brands:
#             if brand in title.lower():
#                 # Strip out the time zone junk from the date for cleaner output
#                 short_date = " ".join(pub_date.split(" ")[1:4])
#                 print(f"- [{brand.upper()}] {short_date} | {title} | {link}")
#                 found_any = True
#                 break # Move to next article so we don't print duplicates
                
#     if not found_any:
#         print(f"No breaking news or market updates found for {', '.join(brands)} in the last 7 days.")
        
# except Exception as e:
#     print(f"Execution Error: {e}")
# EOF

#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/../../.venv/bin/python"

if [ -f "$VENV_PYTHON" ]; then
    EXEC_CMD="$VENV_PYTHON"
else
    EXEC_CMD="python3"
fi

$EXEC_CMD - "$1" << 'EOF'
# Add this to your imports at the top:
import email.utils
from datetime import datetime
import sys, json, urllib.request
import xml.etree.ElementTree as ET

try:
    args = json.loads(sys.argv[1])
    brands = args.get("target_brands", [])
    
    if not brands:
        print("Error: No target brands provided by the LLM.")
        sys.exit(1)

    target_brands = [b.lower() for b in brands]
    
    # Expand our sources for a global + local view
    feeds = [
        ("TheDriven", "https://thedriven.io/feed/"),
        ("Electrek", "https://electrek.co/feed/"),
        ("CleanTechnica", "https://cleantechnica.com/feed/")
    ]
    
    print("--- TYPE: EV MARKET SCAN ---")
    print("STATUS: SUCCESS")
    print(f"TARGETS: {', '.join(brands).upper()}")
    print("RAW DATA:")
    
    articles_found = []

    for site_name, url in feeds:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (IronClaw Multi-Scanner)'})
            with urllib.request.urlopen(req, timeout=5) as response:
                xml_data = response.read()
                
            root = ET.fromstring(xml_data)
            
            for item in root.findall('.//item'):
                title = item.find('title').text
                link = item.find('link').text
                pub_date = item.find('pubDate').text
                
                for brand in target_brands:
                    if brand in title.lower():
                        # Smarter Date Parsing
                        try:
                            # Try to parse standard RSS date
                            parsed_date = email.utils.parsedate_to_datetime(pub_date)
                            short_date = parsed_date.strftime("%d %b %Y")
                        except:
                            # Fallback if the site uses a weird format
                            short_date = pub_date[:11] 
                            
                        articles_found.append(f"- [{brand.upper()}] {short_date} | {title} ({site_name}) | {link}")
                        break
                        
        except Exception as e:
            # If a site blocks us or goes down, just skip it quietly
            continue 

    # --- NATIVE MARKDOWN FORMATTING ---
    print("--- TYPE: EV MARKET SCAN ---")
    print("STATUS: SUCCESS")
    print(f"TARGETS: {', '.join(brands).upper()}")
    print("RAW DATA:")
    
    if articles_found:
        print("\n| Date | Source | Brand | Headline |")
        print("| :--- | :--- | :--- | :--- |")
        for article in articles_found[:12]:
            print(f"| {article['date']} | {article['source']} | {article['brand']} | [{article['title']}]({article['link']}) |")
    else:
        print(f"No breaking news found across monitored sources for {', '.join(brands).upper()}.")
        
except Exception as e:
    print(f"Execution Error: {e}")
EOF