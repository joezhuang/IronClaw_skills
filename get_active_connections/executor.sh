#!/bin/bash

lsof -i -P -n | grep ESTABLISHED | awk '{
    split($9, conn, "->");
    remote = conn[2];
    sub(/:[0-9]+$/, "", remote);
    gsub(/[\[\]]/, "", remote);

    # Filter out Local/Loopback/Link-Local
    if (remote !~ /^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|fe80:|::1)/ && remote != "") {
        
        # Build the curl command directly. 
        # We use \" to escape quotes for the grep pattern.
        cmd = "curl -s https://ipinfo.io/" remote "/json | grep -E \"(hostname|city|region|country|org)\"";
        
        printf "%-15s -> %-15s | ", $1, remote;
        system(cmd);
    }
}' | sort | uniq