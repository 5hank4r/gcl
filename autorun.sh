#!/bin/bash

# Define color codes
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"

# Function to print a message with color
print_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${RESET}"
}

# Function to prompt for user input with color
prompt_input() {
  local prompt="$1"
  local default="$2"
  read -p "$(print_message "${CYAN}" "$prompt") [$default]: " input
  echo "${input:-$default}"
}

# Function to check if downloaded files are non-empty
check_downloads() {
  local dir="$1"
  local fail_count=0

  for file in "$dir"/*; do
    if [ -f "$file" ]; then
      if [ ! -s "$file" ]; then
        print_message "$RED" "Warning: $file is empty or failed to download."
        ((fail_count++))
      else
        print_message "$GREEN" "Success: $file downloaded and verified."
      fi
    fi
  done

  if [ $fail_count -ne 0 ]; then
    print_message "$RED" "Some files failed to download. Check the warnings above."
    return 1
  fi

  return 0
}

# Prompt for input email file and base output directory
INPUT_EMAIL_FILE=$(prompt_input "Enter the path to the input email file" "input_access_mail.txt")
BASE_OUTPUT_DIRECTORY=$(prompt_input "Enter the name for the base output directory" "subdirectory")
OUTPUT_DIRECTORY="output/${BASE_OUTPUT_DIRECTORY}"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIRECTORY"
echo

# Run the Go script to generate accessible URLs and access_mail
print_message "$BLUE" "Running gclv4.go..."
go run gcl.go -file "$INPUT_EMAIL_FILE" -au "${OUTPUT_DIRECTORY}/access_url.txt" -ae "${OUTPUT_DIRECTORY}/access_mail.txt" -no-color -threads 50

if [ $? -ne 0 ]; then
  print_message "$RED" "Error: gclv4.go script failed."
  exit 1
fi
echo

# Extract and sort unique URLs
print_message "$BLUE" "Processing URLs..."
awk '/Accessible: /{print $2}' "${OUTPUT_DIRECTORY}/access_url.txt" | sort -u > "${OUTPUT_DIRECTORY}/finalaccessurl.txt"

if [ $? -ne 0 ]; then
  print_message "$RED" "Error: URL processing failed."
  exit 1
fi
echo

# Download the files
print_message "$BLUE" "Downloading files..."
bash "./download.sh" "${OUTPUT_DIRECTORY}/finalaccessurl.txt" "${OUTPUT_DIRECTORY}/download"

if [ $? -ne 0 ]; then
  print_message "$RED" "Error: Download script failed."
  exit 1
fi
echo

# Check downloaded files
print_message "$BLUE" "Verifying downloaded files..."
check_downloads "${OUTPUT_DIRECTORY}/download"

if [ $? -ne 0 ]; then
  print_message "$RED" "Download verification failed."
  exit 1
fi
echo

# Run the Go analysis program
print_message "$BLUE" "Running File Analyzer..."
go run analyz.go -dir "${OUTPUT_DIRECTORY}/download"

if [ $? -ne 0 ]; then
  print_message "$RED" "Error: Analysis with sev4 failed."
  exit 1
fi

# Display success message
print_message "$GREEN" "All steps completed successfully."
