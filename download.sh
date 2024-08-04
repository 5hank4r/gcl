#!/bin/bash

# Check if the input file and output directory are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <url_file> <output_directory>"
  exit 1
fi

URL_FILE=$1
OUTPUT_DIR=$2

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Read URLs from the file, process each URL, and download the file
cat "$URL_FILE" | while IFS= read -r url; do
  # Extract email part and construct the filename
  email=$(echo "$url" | awk -F'ical/' '{print $2}' | awk -F'/' '{print $1}')
  fileName="${email}basic.ics"

  # Download the file using wget
  wget -q -O "$OUTPUT_DIR/$fileName" "$url"

  if [ $? -eq 0 ]; then
    echo "Successfully downloaded: $url as $fileName"
  else
    echo "Failed to download: $url"
  fi
done

echo "Download complete."
