#!/bin/bash

python3 -c '
import sys, json, os, urllib.request

try:
    args = json.loads(sys.argv[1])
    query = args.get("query", "")
    api_key = os.environ.get("SERPER_API_KEY")

    if not api_key:
        print("Error: SERPER_API_KEY missing.")
        sys.exit(1)

    # --- ATTEMPT 1: Force the Dedicated Shopping API ---
    shop_url = "https://google.serper.dev/shopping"
    shop_data = json.dumps({"q": query, "gl": "au"}).encode("utf-8")
    req_shop = urllib.request.Request(shop_url, data=shop_data, headers={"X-API-KEY": api_key, "Content-Type": "application/json"})
    
    with urllib.request.urlopen(req_shop) as response:
        shop_res = json.loads(response.read().decode())

    formatted = ""
    if "shopping" in shop_res and len(shop_res["shopping"]) > 0:
        formatted += "--- TYPE: SHOPPING DATA ---\n"
        for i, item in enumerate(shop_res["shopping"][:8]):
            title = item.get("title", "Unknown")
            source = item.get("source", "Unknown")
            price = item.get("price", "N/A")
            link = item.get("link", "")
            formatted += f"[{i+1}] {title} | {source} | {price}\nURL: {link}\n\n"
            
    # --- ATTEMPT 2: Fallback to Organic if Shopping is empty ---
    else:
        org_url = "https://google.serper.dev/search"
        org_data = json.dumps({"q": query, "gl": "au"}).encode("utf-8")
        req_org = urllib.request.Request(org_url, data=org_data, headers={"X-API-KEY": api_key, "Content-Type": "application/json"})
        
        with urllib.request.urlopen(req_org) as response:
            org_res = json.loads(response.read().decode())
            
        if "organic" in org_res and len(org_res["organic"]) > 0:
            formatted += "--- TYPE: ORGANIC SEARCH DATA ---\n"
            for i, item in enumerate(org_res["organic"][:5]):
                title = item.get("title", "Unknown")
                snippet = item.get("snippet", "No snippet")
                link = item.get("link", "")
                formatted += f"[{i+1}] {title}\nSnippet: {snippet}\nURL: {link}\n\n"

    if not formatted:
        print("No relevant data found for this query.")
    else:
        print(formatted)

except Exception as e:
    print(f"Execution Error: {e}")
' "$1"