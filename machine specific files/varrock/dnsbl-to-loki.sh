#!/bin/sh
LOKI_HOST="draynor.home"
LOKI_PORT="32747"
HOSTNAME=$(hostname -s)
while true; do
    tail -F /var/log/pfblockerng/dnsbl.log | while IFS= read -r line; do
        [ -z "$line" ] && continue
        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        # RFC 5424: <PRI>VERSION TIMESTAMP HOSTNAME APPNAME PROCID MSGID STRUCTURED-DATA MSG
        # PRI 14 = facility:user(1) + severity:info(6)
        printf '<14>1 %s %s pfblockerng - - - %s\n' "$ts" "$HOSTNAME" "$line" | \
            nc -u -w 1 "$LOKI_HOST" "$LOKI_PORT"
    done
    sleep 5
done
