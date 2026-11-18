#!/bin/bash
# usage: download-animation.sh <asset id> <path under asset/animation, without an extension>
set -e
# an animation only comes down for whoever owns it, as the keyframe sequence it was uploaded from
mkdir -p "$(dirname "asset/animation/${2}")"
curl -L --fail \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    -b ".ROBLOSECURITY=${ROBLOSECURITY}" \
    --compressed \
    -o "asset/animation/${2}.rbxm" \
    "https://assetdelivery.roblox.com/v1/asset/?id=${1}"
