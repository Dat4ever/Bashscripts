#!/usr/bin/env bash

## name: yt-dlp-mp4.bash
## author: Dat (and AI)
## description: 
## usage: bash yt-dlp-mp4.bash <URL> [Resolution]

set -euo pipefail

URL=$1
RES=${2:-480}
# Define the download directory
DOWNLOAD_DIR="$HOME/Downloads/yt-dlp-downloads"

# Create the directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

echo "Targeting resolution: ${RES}p"
echo "Destination: $DOWNLOAD_DIR"
echo "Embedding chapters and metadata..."

# yt-dlp command
# The -P flag sets the download path
yt-dlp -f "bestvideo[height<=${RES}]+bestaudio/best[height<=${RES}]" \
    --merge-output-format mp4 \
    --embed-chapters \
    --embed-metadata \
    -P "$DOWNLOAD_DIR" \
    -o "%(title)s.%(ext)s" \
    "$URL"

if [ $? -eq 0 ]; then
    echo -e "\n Done! Video saved in $DOWNLOAD_DIR"
else
    echo -e "\n Download failed."
    exit 1
fi
