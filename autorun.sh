#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Define the static output directory and download directory
OUTPUT_DIR="output"
DOWNLOAD_DIR="download"

# Check if the subdirectory and email file name are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo -e "${RED}Error: Subdirectory or email file name not provided.${RESET}"
  echo "Usage: $0 <subdirectory> <email_file>"
  exit 1
fi

# Set subdirectory, email file, and full paths
SUB_DIR="$1"
EMAIL_FILE="$2"
FULL_DIR="$OUTPUT_DIR/$SUB_DIR"
FULL_DOWNLOAD_DIR="$FULL_DIR/$DOWNLOAD_DIR"

# Create the output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
  echo -e "${YELLOW}Creating main output directory: $OUTPUT_DIR${RESET}"
  mkdir -p "$OUTPUT_DIR"
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Unable to create directory $OUTPUT_DIR${RESET}"
    exit 1
  fi
fi

# Create the subdirectory if it doesn't exist
echo -e "${YELLOW}Creating subdirectory: $FULL_DIR${RESET}"
mkdir -p "$FULL_DIR"
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Unable to create directory $FULL_DIR${RESET}"
  exit 1
fi

# Create the download directory if it doesn't exist
echo -e "${YELLOW}Creating download directory: $FULL_DOWNLOAD_DIR${RESET}"
mkdir -p "$FULL_DOWNLOAD_DIR"
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Unable to create directory $FULL_DOWNLOAD_DIR${RESET}"
  exit 1
fi
echo

# Check if the email file exists
if [ ! -f "$EMAIL_FILE" ]; then
  echo -e "${RED}Error: Email file $EMAIL_FILE not found.${RESET}"
  exit 1
fi

# Generate and check accessible URLs
echo -e "${CYAN}Checking accessible URLs...${RESET}"
while IFS= read -r email; do
  url="https://calendar.google.com/calendar/ical/$email/public/basic.ics"
  echo "$url"
done < "$EMAIL_FILE" | httpx -no-color -mc 200 -silent | tee "$FULL_DIR/accessurl.txt" | awk '{print $1}'
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: httpx encountered issues.${RESET}"
  exit 1
fi
echo

# Display the number of accessible URLs
echo -e "${CYAN}Number of accessible URLs:${RESET}"
wc -l "$FULL_DIR/accessurl.txt"
echo

# Download files from accessible URLs
echo -e "${CYAN}Starting downloads...${RESET}"
while IFS= read -r url; do
  # Generate the filename for email_basic.ics
  email_filename=$(echo "$url" | sed 's/.*\/calendar\/ical\/\([^\/]*\)\/public\/basic.ics/email_\1_basic.ics/')

  echo -e "${GREEN}Downloading $url to $FULL_DOWNLOAD_DIR/$email_filename${RESET}"
  wget -q "$url" -O "$FULL_DOWNLOAD_DIR/$email_filename"
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: wget encountered issues while downloading $url${RESET}"
  fi
done < "$FULL_DIR/accessurl.txt"
echo

# Run the Go script to analyze files in the download directory
echo -e "${CYAN}Running Sensitive Analysis on $FULL_DOWNLOAD_DIR...${RESET}"
go run analyz.go -dir "$FULL_DOWNLOAD_DIR"
if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Analyz.go encountered issues.${RESET}"
  exit 1
fi