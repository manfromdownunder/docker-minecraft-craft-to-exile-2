#!/bin/bash
set -e

# Check for architecture and skip certain steps if it's ARM
if [ "$ARCH" == "arm64" ] || [ "$ARCH" == "arm" ]; then
    echo "ARM architecture detected, skipping downloadFromCurseForge.js"
    exit 0
fi

# Check for file argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_file_with_urls>"
    exit 1
fi

# Convert relative file path to absolute
FILE_NAME="$1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILE_PATH="$SCRIPT_DIR/$FILE_NAME"

echo "Looking for mods list at: $FILE_PATH"

# Create a directory for npm and puppeteer/chrome files
BINARY_DIR="$SCRIPT_DIR/binaries"
mkdir -p "$BINARY_DIR"

# Check if libnss3 library for ChromeDriver is installed
if ! dpkg -l | grep -q libnss3; then
    sudo apt-get update
    sudo apt-get install -y libnss3
fi

# Install Node.js and Puppeteer
(
    cd "$BINARY_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"

    nvm install node
    npm install puppeteer@12.0.1  --prefix "$BINARY_DIR"
    npm install puppeteer-extra puppeteer-extra-plugin-stealth
    npm install unzipper
)

# Get Chromium executable path
export NODE_PATH="$BINARY_DIR/node_modules"
CHROME_PATH=$(node -e "const puppeteer = require('puppeteer'); console.log(puppeteer.executablePath());")
echo "Chromium path: $CHROME_PATH"

# Ensure puppeteer-extra is installed
if [ ! -d "$BINARY_DIR/node_modules/puppeteer-extra" ]; then
    echo "Failed to install puppeteer-extra. Exiting."
    exit 1
fi

# Read URLs from the file and download sequentially
if [ ! -f "$FILE_PATH" ]; then
    echo "File does not exist or is not readable. Exiting."
    exit 1
fi

echo "About to enter while loop, reading from file: $FILE_PATH"

while IFS= read -r DOWNLOAD_URL; do
    echo "Processing URL: $DOWNLOAD_URL"
    FOLDER_STRUCTURE="${DOWNLOAD_URL#https://www.curseforge.com/}"
    mkdir -p "$SCRIPT_DIR/$FOLDER_STRUCTURE"
    echo "About to run Node.js script with CHROME_PATH: $CHROME_PATH"
    echo "FULL_DIR_PATH being sent to Node.js: $SCRIPT_DIR/$FOLDER_STRUCTURE"
    node "$SCRIPT_DIR/downloadFromCurseForge.js" "$DOWNLOAD_URL" "$CHROME_PATH" "$SCRIPT_DIR/$FOLDER_STRUCTURE"
done < "$FILE_PATH"
