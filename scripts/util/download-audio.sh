#!/bin/bash
# usage: download-audio.sh <asset id> <path under asset/audio, without an extension>
set -e
# audio comes down in whatever format it was uploaded in, its first bytes say which
tmp="$(mktemp)"
curl -L --fail \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    -H "Accept: audio/*" \
    -b ".ROBLOSECURITY=${ROBLOSECURITY}" \
    --compressed \
    -o "$tmp" \
    "https://assetdelivery.roblox.com/v1/asset/?id=${1}"
case "$(head -c 4 "$tmp" | xxd -p)" in
    4f676753) ext="ogg" ;;
    52494646) ext="wav" ;;
    664c6143) ext="flac" ;;
    *) ext="mp3" ;;
esac
mkdir -p "$(dirname "asset/audio/${2}")"
mv "$tmp" "asset/audio/${2}.${ext}"
