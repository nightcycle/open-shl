#!/bin/bash
set -e
curl -L \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    -H "Accept: image/png,image/jpeg,image/*" \
    -b ".ROBLOSECURITY=${ROBLOSECURITY}" \
    --compressed \
    -o "asset/texture/${1}.png" \
    "https://assetdelivery.roblox.com/v1/asset/?id=${1}"