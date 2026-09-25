## Log Aggregation (pfBlockerNG → Loki)

pfBlockerNG's DNSBL log (`/var/log/pfblockerng/dnsbl.log` on Varrock) captures every DNS block decision in a CSV format:

```
DNSBL-python,Sep 22 22:38:59,trace.svc.ui.com,192.168.1.21,Python,DNSBL,DNSBL_MitchList,trace.svc.ui.com,adservers,+
```

These logs are shipped to [Loki](https://grafana.com/oss/loki/) (running on Draynor) via [Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/) and are queryable in Grafana.

### Architecture

```
Varrock (pfSense)                  Draynor (k3s)
─────────────────                  ──────────────────────────────
dnsbl.log
    │
    │  tail -F
    ▼
dnsbl-to-loki.sh  ──UDP/RFC5424──► Promtail (NodePort 32747)
                    syslog                │
                                         │  HTTP push
                                         ▼
                                        Loki
                                         │
                                         ▼
                                       Grafana
```

### Why the custom script?

pfSense's built-in remote syslog only ships system-level log categories (firewall events, DHCP, auth, etc.). pfBlockerNG writes its DNSBL log directly to disk via its Python resolver process — it does not pipe through syslog at all, so there is no GUI setting to ship it remotely.

The script [`machine specific files/varrock/dnsbl-to-loki.sh`](./machine%20specific%20files/varrock/dnsbl-to-loki.sh) runs persistently on Varrock, tailing `dnsbl.log` and forwarding each line to Promtail over UDP.

### RFC 5424 formatting

FreeBSD's `logger` utility sends **RFC 3164** syslog format. Promtail's syslog receiver expects **RFC 5424**. Sending RFC 3164 causes Promtail to log `error parsing syslog stream: expecting a version value in the range 1-999`. To work around this, the script manually constructs RFC 5424 frames and sends them via `nc`:

```sh
printf '<14>1 %s %s pfblockerng - - - %s\n' "$ts" "$HOSTNAME" "$line" | \
    nc -u -w 1 "$LOKI_HOST" "$LOKI_PORT"
```

### Deploying the script on Varrock

1. Copy [`dnsbl-to-loki.sh`](./machine%20specific%20files/varrock/dnsbl-to-loki.sh) to `/usr/local/bin/dnsbl-to-loki.sh` on Varrock and `chmod +x` it.
2. Install the **Shellcmd** pfSense package (System → Package Manager).
3. Add a Shellcmd entry (Services → Shellcmd): command `/usr/local/bin/dnsbl-to-loki.sh`, type `shellcmd`. This starts it automatically on every boot.
4. Start it immediately without rebooting: `nohup /usr/local/bin/dnsbl-to-loki.sh > /dev/null 2>&1 &`