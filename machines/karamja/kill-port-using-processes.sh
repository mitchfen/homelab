#!/usr/bin/env bash
# Finds and kills processes listening on any port except 22 (SSH)

set -euo pipefail

echo "Scanning for processes listening on ports other than 22..."

# Get PIDs of processes listening on ports != 22
mapfile -t pids < <(
  ss -tlnp | awk 'NR>1 {print $4, $6}' | \
  while read -r addr proc; do
    port="${addr##*:}"
    [[ "$port" == "22" ]] && continue
    # Extract PID from ss output like: users:(("name",pid=1234,fd=5))
    pid=$(echo "$proc" | grep -oP 'pid=\K[0-9]+' || true)
    [[ -n "$pid" ]] && echo "$pid"
  done | sort -u
)

if [[ ${#pids[@]} -eq 0 ]]; then
  echo "No processes found listening on ports other than 22."
  exit 0
fi

for pid in "${pids[@]}"; do
  name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
  port_list=$(ss -tlnp | awk -v p="pid=$pid" '$0 ~ p {print $4}' | awk -F: '{print $NF}' | paste -sd,)
  echo "Killing PID $pid ($name) on port(s): $port_list"
  kill "$pid" && echo "  -> Sent SIGTERM to $pid" || echo "  -> Failed to kill $pid (may need sudo)"
done

echo "Done."
