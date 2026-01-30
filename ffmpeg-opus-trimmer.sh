#!/usr/bin/env bash

## name: ffmpeg-opus-trimmer.sh
## description: Removes first and/or last seconds from opus while preserving quality and album art.
## usage: bash ffmpeg-opus-trimmer.sh <filename> <start_seconds> <end_seconds>

INPUT="$1"
START_OFFSET="$2"
END_OFFSET="$3"

# Validation
if [[ -z "$INPUT" || -z "$START_OFFSET" || -z "$END_OFFSET" ]]; then
    echo "Usage: $0 <filename> <start_seconds> <end_seconds>"
    exit 1
fi

DIR=$(dirname "$INPUT")
BASE=$(basename "$INPUT")
TEMP_COVER="${DIR}/temp_cover.jpg"
OUTPUT="${DIR}/trimmed_${BASE}"

# Extract cover art
echo "Processing: $BASE"
ffmpeg -i "$INPUT" -an -vcodec copy "$TEMP_COVER" -y -loglevel error

# Calculate Duration and Trim Audio (Zero Quality Loss)
TOTAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
NEW_DURATION=$(echo "$TOTAL_DURATION - $START_OFFSET - $END_OFFSET" | bc)

echo "Trimming $START_OFFSET seconds from start and $END_OFFSET from end..."
ffmpeg -i "$INPUT" -ss "$START_OFFSET" -t "$NEW_DURATION" -c:a copy -vn "$OUTPUT" -y -loglevel error

# Inject Cover Art using kid3-cli
if [[ -f "$TEMP_COVER" ]]; then
    echo "Injecting cover art..."
    kid3-cli -c "set picture:'$TEMP_COVER' 'Front Cover'" "$OUTPUT"
    rm "$TEMP_COVER"
    echo "Success!"
else
    echo "Error!"
fi
