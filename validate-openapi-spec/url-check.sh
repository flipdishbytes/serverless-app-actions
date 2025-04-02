#!/bin/bash

RETRY_COUNT=0

if [[ -z "$URL" ]]; then
    echo "Error: URL is not set. Please provide a valid URL."
    exit 1
fi

if [[ -z "$MAX_RETRIES" || "$MAX_RETRIES" -eq 0 ]]; then
    MAX_RETRIES=4 # Default to 4 retries if not set or empty
fi

echo "Waiting for $URL to be available..."
while true; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$URL" || echo "000")

    if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "301" ]]; then
        echo "SST API URL is available."
        break
    else
        echo "SST API URL is not available yet. Status: $HTTP_STATUS (Attempt: $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    fi

    ((RETRY_COUNT++))
    if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
        echo "SST API URL did not become available after $((MAX_RETRIES * 15)) seconds."
        exit 1
    fi
    echo "Waiting for 15 seconds..."
    sleep 15
done
