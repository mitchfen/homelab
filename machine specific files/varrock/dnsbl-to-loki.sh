#!/bin/sh
LOKI_URL="https://loki.fenner.nexus/loki/api/v1/push"
HOSTNAME=$(hostname -s)
LOG_FILE="/var/log/pfblockerng/dnsbl.log"
BATCH_FILE="/tmp/loki_batch.$$"

# Clean up temp file on exit
trap 'rm -f "$BATCH_FILE" "$BATCH_FILE.send"' EXIT INT TERM

# Wait until log file exists (e.g. fresh boot)
while [ ! -f "$LOG_FILE" ]; do
    sleep 2
done

flush_batch() {
    [ ! -s "$BATCH_FILE" ] && return
    # Atomically move batch to isolate from concurrent writes
    mv "$BATCH_FILE" "$BATCH_FILE.send"
    
    # Strip trailing comma from the list of JSON tuples
    entries=$(sed '$ s/,$//' "$BATCH_FILE.send")
    rm -f "$BATCH_FILE.send"

    payload="{\"streams\": [{\"stream\": {\"job\": \"pfsense\", \"host\": \"$HOSTNAME\"}, \"values\": [$entries]}]}"

    # Push to Loki via HTTPS with 5s timeout; don't die on failure
    curl -s -m 5 -X POST -H "Content-Type: application/json" --data "$payload" "$LOKI_URL" > /dev/null 2>&1
}

# Background flush worker: ensures logs are pushed at least every 3 seconds even under low traffic
(
    while true; do
        sleep 3
        flush_batch
    done
) &
FLUSHER_PID=$!
trap 'kill "$FLUSHER_PID" 2>/dev/null; rm -f "$BATCH_FILE" "$BATCH_FILE.send"' EXIT INT TERM

# Main ingest loop: tail new lines (-n 0 prevents duplicates on startup)
while true; do
    tail -n 0 -F "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
        [ -z "$line" ] && continue

        # Nanosecond timestamp (FreeBSD date +%s is seconds; append 9 zeros)
        ts="$(date +%s)000000000"

        # Escape backslashes and double quotes for JSON safety
        clean_line=$(printf '%s' "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')

        # Append ["<nanoseconds>", "<line>"],
        printf '["%s", "%s"],\n' "$ts" "$clean_line" >> "$BATCH_FILE"

        # If batch reaches 25 entries, flush immediately
        lines_count=$(wc -l < "$BATCH_FILE" 2>/dev/null || echo 0)
        if [ "$lines_count" -ge 25 ]; then
            flush_batch
        fi
    done

    sleep 2
done


