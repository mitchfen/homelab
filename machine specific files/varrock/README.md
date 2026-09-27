## Log Aggregation (pfBlockerNG → Loki)

pfBlockerNG's DNSBL log (`/var/log/pfblockerng/dnsbl.log` on Varrock) captures every DNS block decision in a CSV format:

```
DNSBL-python,Sep 22 22:38:59,trace.svc.ui.com,192.168.1.21,Python,DNSBL,DNSBL_MitchList,trace.svc.ui.com,adservers,+
```

These logs are shipped directly to [Loki](https://grafana.com/oss/loki/) (running on Draynor) over HTTPS via [Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) and are queryable in Grafana.

### Architecture

```
Varrock (pfSense)                         Draynor (k3s)
─────────────────                         ──────────────────────────────
dnsbl.log
    │
    │  tail -n 0 -F
    ▼
dnsbl-to-loki.sh (batch buffer)
    │
    │  HTTPS POST /loki/api/v1/push
    ▼
Nginx Proxy Manager (loki.fenner.nexus) ──► Loki (:3100)
                                                │
                                                ▼
                                             Grafana
```

### Why the custom script?

pfSense's built-in remote syslog only ships system-level log categories (firewall events, DHCP, auth, etc.). pfBlockerNG writes its DNSBL log directly to disk via its Python resolver process — it does not pipe through syslog at all, so there is no GUI setting to ship it remotely.

The script [`machine specific files/varrock/dnsbl-to-loki.sh`](./dnsbl-to-loki.sh) runs persistently on Varrock supervised by FreeBSD's native `daemon -r`. It tails `dnsbl.log`, batches entries in memory/tmp buffer, and pushes JSON batches directly to Loki's HTTP API (`https://loki.fenner.nexus/loki/api/v1/push`). This eliminates the need for Promtail, syslog format translations, or opening NodePorts on Kubernetes.


### Deploying the script on Varrock

1. Copy [`dnsbl-to-loki.sh`](./dnsbl-to-loki.sh) to `/usr/local/bin/dnsbl-to-loki.sh` on Varrock and `chmod +x` it.
2. Install the **Shellcmd** pfSense package (System → Package Manager).
3. Add a Shellcmd entry (Services → Shellcmd):
   - Command: `/usr/sbin/daemon -r -f -p /var/run/dnsbl-to-loki.pid /usr/local/bin/dnsbl-to-loki.sh`
   - Type: `shellcmd`
   
   The `-r` flag causes FreeBSD's native `daemon` supervisor to monitor the script and automatically restart it within seconds if it ever exits or crashes.
4. Kill any old unmanaged instances and start the supervised daemon immediately:
   ```sh
   pkill -f dnsbl-to-loki.sh
   /usr/sbin/daemon -r -f -p /var/run/dnsbl-to-loki.pid /usr/local/bin/dnsbl-to-loki.sh
   ```
5. Verify it's running:
   ```sh
   ps aux | grep dnsbl
   ```
   You should see both `/usr/sbin/daemon` and `/usr/local/bin/dnsbl-to-loki.sh`.