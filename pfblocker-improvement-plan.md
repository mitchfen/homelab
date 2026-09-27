# pfBlockerNG → Loki Log Shipping Improvement Plan

## 1. Context & Problem Statement

Currently, DNSBL block logs from pfBlockerNG on **Varrock** (`/var/log/pfblockerng/dnsbl.log`) are shipped to Promtail / Loki on **Draynor** (`draynor.home:32747/UDP`) using [`machine specific files/varrock/dnsbl-to-loki.sh`](./machine%20specific%20files/varrock/dnsbl-to-loki.sh).

### Identified Issues with Current Setup
1. **No Process Supervision**: Started via `nohup` / `shellcmd` without a supervisor. If the process terminates, crashes, or encounters an unhandled pipe error, pfSense does not restart it until the next reboot.
2. **Subshell & Pipe Lockup**: `tail -F ... | while read ...` runs in a subshell. If `tail` hangs, terminates, or blocks on stdout, the outer `while true` loop never reaches its retry block.
3. **Heavy Process Forking**: Spawns a new `date` and a new `nc` command for *every single* log line. During high DNS traffic or burst queries, this causes high context switching, socket churn, and potential process table / buffer stalls.
4. **Log Duplication on Restart**: Default `tail -F` (without `-n 0`) re-reads and re-ships the last 10 lines from the log file whenever the process starts, resulting in duplicate entries and inflated metrics in Loki/Grafana.

---

## 2. Proposed Options

### Option A: Resilient FreeBSD `daemon -r` + Persistent Pipeline (Recommended)
Retain zero external dependencies on pfSense by using FreeBSD's built-in `daemon` supervisor utility and optimizing the shell pipeline.

- **Supervisor**: FreeBSD's native `/usr/sbin/daemon -r` watches the child process and immediately restarts it if it exits or crashes.
- **Persistent Network Stream**: Pipe the entire stream into a single persistent `nc -u` process rather than invoking `nc` once per log line.
- **Duplicate Prevention**: Use `tail -n 0 -F` so that upon service restart, old log entries are not resent to Loki.
- **Log Rotation Handling**: `tail -F` automatically re-opens the file when pfBlockerNG rotates `dnsbl.log` (tracking filename rather than descriptor).
- **Caveat**: Records written during the brief downtime of a restart or machine reboot will not be backfilled (offset is not tracked).

### Option B: Dedicated Log Agent (Promtail / Vector on FreeBSD)
Install a native agent on FreeBSD/pfSense that tracks log file cursors on disk (e.g. `positions.yaml` or state DB).
- **Pros**: Zero missed records and zero duplicate records across restarts and reboots.
- **Cons**: Extra packages/binaries on pfSense that could get wiped or broken across pfSense OS upgrades.

---

## 3. Implementation Steps for Option A

### Step 1: Update `dnsbl-to-loki.sh`
Update [`machine specific files/varrock/dnsbl-to-loki.sh`](./machine%20specific%20files/varrock/dnsbl-to-loki.sh) with the hardened streaming logic:

```sh
#!/bin/sh
LOKI_HOST="draynor.home"
LOKI_PORT="32747"
HOSTNAME=$(hostname -s)
LOG_FILE="/var/log/pfblockerng/dnsbl.log"

# Wait until the log file exists (e.g. on clean boot)
while [ ! -f "$LOG_FILE" ]; do
    sleep 2
done

# Stream lines directly through a persistent nc connection.
# If tail or nc fails, the loop will cleanly restart.
while true; do
    tail -n 0 -F "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
        [ -z "$line" ] && continue
        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        # RFC 5424: <PRI>VERSION TIMESTAMP HOSTNAME APPNAME PROCID MSGID STRUCTURED-DATA MSG
        printf '<14>1 %s %s pfblockerng - - - %s\n' "$ts" "$HOSTNAME" "$line"
    done | nc -u "$LOKI_HOST" "$LOKI_PORT"

    sleep 2
done
```

### Step 2: Deploy to Varrock
1. Copy the script to `/usr/local/bin/dnsbl-to-loki.sh` on Varrock:
   ```sh
   chmod +x /usr/local/bin/dnsbl-to-loki.sh
   ```
2. Kill any lingering instances of old `dnsbl-to-loki.sh` or unmanaged `nc` processes:
   ```sh
   pkill -f dnsbl-to-loki.sh
   ```

### Step 3: Configure FreeBSD Daemon Supervision via Shellcmd
In the pfSense web GUI (**Services → Shellcmd**):
1. Locate or edit the Shellcmd entry for `dnsbl-to-loki.sh`.
2. Change the command to:
   ```sh
   /usr/sbin/daemon -r -f -p /var/run/dnsbl-to-loki.pid /usr/local/bin/dnsbl-to-loki.sh
   ```
3. Command type: `shellcmd`.
4. Start it immediately without rebooting:
   ```sh
   /usr/sbin/daemon -r -f -p /var/run/dnsbl-to-loki.pid /usr/local/bin/dnsbl-to-loki.sh
   ```

### Step 4: Verification
- Verify running processes on Varrock:
  ```sh
  ps aux | grep dnsbl
  ```
  Should show both `/usr/sbin/daemon` and `/usr/local/bin/dnsbl-to-loki.sh`.
- Test recovery:
  Kill the child shell script process (`pkill -9 -f /usr/local/bin/dnsbl-to-loki.sh`) and verify that `daemon -r` immediately relaunches it within seconds.
- Check Grafana on Draynor to confirm logs stream into the pfBlockerNG DNSBL panel without duplication.

### Step 5: Update Repository Documentation
Update [`machine specific files/varrock/README.md`](./machine%20specific%20files/varrock/README.md) to document the `daemon -r` supervision and revised Shellcmd command.
