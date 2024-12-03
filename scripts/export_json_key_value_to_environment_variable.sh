#!/bin/bash

# Function to convert JSON string to key-value pairs
json_to_key_value_pairs() {
  local json_string="$1"

  # Extract key-value pairs using jq and store them in a string
  local kv_pairs=$(echo "$json_string" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"')

  # Output the key-value pairs
  echo "$kv_pairs"
}

# Main function to handle the input JSON and export variables
process_json() {
  local json_string="$1"
  local prefix="$2"

  echo "Input JSON: $json_string"

  # Call the function and store the key-value pairs
  local key_value_pairs=$(json_to_key_value_pairs "$json_string")

  # Loop through the key-value pairs and set variables
  while IFS= read -r pair; do

    echo "Pair: $pair"
    # Split the pair into key and value
    IFS='=' read -r key value <<< "$pair"

    echo "Key: $key"

    # Sanitize the key by replacing '.' with '_'
    sanitized_key=$(echo "$key" | sed 's/\./_/g')

    # Export each key-value pair as a variable
    export "$sanitized_key=$value"

    # Processed variable
    echo "Processed Variable: $sanitized_key=$value"

    if [ -n "$GITHUB_ACTIONS" ]; then
      echo "Running in GitHub Actions"

      vault_key="${prefix}${sanitized_key}"
      echo "KEY: $vault_key"
      echo "VALUE: $value"
      echo "${vault_key}"="${value}" >> "$GITHUB_ENV"
    fi

  done <<< "$key_value_pairs"
}

# Check if a JSON string was passed as an argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 '<json_string>'"

  exit 0
fi

# Call the process_json function with the provided JSON string
process_json "$1"
