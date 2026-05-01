#!/usr/bin/env bash
# experiments/openai/using_functions/example.sh


# Define your function
fetch_webpage_text() {
curl -s "$1"
}

# Example usage with OpenAI API
url="https://example.com"
webpage_text=$(fetch_webpage_text "$url")

# Call OpenAI API
response=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
-H "Authorization: Bearer your-api-key" \
-H "Content-Type: application/json" \
-d '{
"model": "gpt-4",
"messages": [
{"role": "user", "content": "What does the webpage say?"},
{"role": "function", "name": "fetch_webpage_text", "content": "'"$url"'"}
]
}')

echo "$response" | jq '.choices[0].message.content'
