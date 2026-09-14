#!/bin/sh
set -e

# a place to put generated code to keep the project config and gitignore simple
if [ ! -d "Generated" ]; then
	mkdir "Generated"
fi
