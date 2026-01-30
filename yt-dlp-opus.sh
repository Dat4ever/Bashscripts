#!/usr/bin/env bash

## name: yt-dlp-opus.sh
## description: Downloads YouTube audio (video or playlist) in Opus format, 
## usage: ./yt-dlp-audio.sh <URL> [ -p | --playlist ]

##################### Configuration #####################
BASE_DIR="$HOME/Downloads/yt-dlp-downloads"
ARCHIVE_FILE="$BASE_DIR/downloaded_archive.txt"

YTDL_OPTS=(
    -x                  # Extract audio only
    --audio-format opus # Convert to Opus format
    --embed-thumbnail   # Embed video thumbnail as cover art
    --audio-quality 0   # Best quality
    --add-metadata      # Embed general metadata (title, artist, etc.)
)
##########################################################

set -euo pipefail

# Create BASE_DIR and Archive file if they don't exist
mkdir -p "$BASE_DIR"

# Check for URL argument
if [ -z "$1" ]; then
    echo "Error: Must provide a YouTube URL."
    echo "Usage: $0 <URL> [ -p | --playlist ]"
    exit 1
fi

video_url="$1"
is_playlist=0

# Check for playlist flag (-p or --playlist)
if [ ! -z "$2" ] && ([ "$2" == "-p" ] || [ "$2" == "--playlist" ]); then
    is_playlist=1
fi

if [ $is_playlist -eq 1 ]; then
    OUTPUT_TEMPLATE="$BASE_DIR/%(playlist)s/%(title)s.%(ext)s"
else
    OUTPUT_TEMPLATE="$BASE_DIR/%(title)s.%(ext)s"
fi

echo "YT-DLP Audio Download Started"
echo "Target URL: $video_url"
echo "Output Path: $BASE_DIR"
echo "Playlist Mode: $([ $is_playlist -eq 1 ] && echo "Yes" || echo "No")"

# Execute yt-dlp command
YT_COMMAND=(
    yt-dlp 
    "${YTDL_OPTS[@]}" 
    --download-archive "$ARCHIVE_FILE" 
    -o "$OUTPUT_TEMPLATE" 
    "$video_url"
)

# Run the command and check exit status
if "${YT_COMMAND[@]}"; then
    echo "Success"
else
    echo "[!]Error"
    echo "Download or processing failed. Check URL and dependencies (yt-dlp, FFmpeg)."
    exit 1
fi

exit 0
