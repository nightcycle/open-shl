#!/bin/sh
set -e

# a place to put generated code to keep the project config and gitignore simple
if [ ! -d "Generated" ]; then
	mkdir "Generated"
fi

classes=("Frame" "CanvasGroup" "ImageButton" "TextButton" "ImageLabel" "TextLabel" "ScrollingFrame" "TextBox" "VideoFrame" "ViewportFrame")
for class in "${classes[@]}"; do
	lune run "scripts/util/generate-react-roblox-types.lune.luau" "Generated/React/Component/${class}.luau" "${class}"
done