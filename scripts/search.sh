#!/bin/bash

query="$1"

# Remove 'ascii' from the beginning if present
if [[ "$query" =~ ^ascii[[:space:]]* ]]; then
    query="${query#ascii}"
    query=$(echo "$query" | xargs)  # trim whitespace
fi

# Path to emoji cache
emoji_cache="$(dirname "$0")/../emojis.json"

if [[ ! -f "$emoji_cache" ]]; then
    echo '{"items":[{"title":"Error","subtitle":"Emoji database file not found","valid":false}]}'
    exit 1
fi

# Convert to lowercase for case-insensitive search
query_lc=$(echo "$query" | tr '[:upper:]' '[:lower:]')

if ! command -v jq >/dev/null 2>&1; then
    echo '{"items":[{"title":"Error","subtitle":"jq is required but not installed. Please install jq: brew install jq","valid":false}]}'
    exit 1
fi

# Use jq for JSON parsing and filtering
results=$(jq -r --arg query "$query_lc" '
  if $query == "" then
    .emojis[]
  else
    .emojis[] |
    select(
      ((.title // "" | ascii_downcase) | test($query)) or
      ((.tags[] // "" | ascii_downcase) | test($query))
    )
  end |
  {
    uid: (.plain | @base64),
    title: (if .title == null or .title == "" then
      "Untitled: " + (.plain | if length > 20 then .[0:20] + "..." else . end)
    else
      .title
    end),
    subtitle: .plain,
    arg: .plain,
    icon: {path: "icon.png"},
    valid: true,
    text: {
      copy: .plain,
      largetype: .plain
    },
    mods: {
      cmd: {
        subtitle: ("Copy to clipboard: " + .plain)
      }
    }
  }
' "$emoji_cache" | jq -s '{items: .}')

# If no results, show a helpful message
if [[ $(echo "$results" | jq '.items | length') -eq 0 ]]; then
    echo '{"items":[{"title":"No ASCII emojis found","subtitle":"Try searching for: table, lenny, happy, sad, etc.","valid":false}]}'
else
    echo "$results"
fi