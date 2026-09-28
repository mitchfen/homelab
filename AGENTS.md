# Agent Context for Homelab

## Environment Details
- **Current Host**: You are always running on `Lumbridge`, and NixOs.
- **Tooling**: `terraform` and `kubectl` contexts are already configured and ready to use. You are welcome to run any read-only, inspection, or non-destructive commands (e.g., `terraform plan`, `terraform fmt`, `kubectl get`, `kubectl describe`, `kubectl logs`, etc.).
- **Draynor Host**: Runs Kubernetes (k3s) on NixOS and hosts most applications. You can ssh here using `ssh mitchfen@draynor`. It requires an SSH key which is already present on Lumbridge.
- **Karamja Host**: Runs Unifi OS Server on Debian. You can ssh here using `ssh mitchfen@karamja`. It requires an SSH key which is already present on Lumbridge.
- **Varrock Host**: Runs pfsense. You can ssh here using `ssh admin@192.168.1.1`. It requires an SSH key which is already present on Lumbridge. Do not SSH here unless absolutely needed.

## Architecture & Deployment
- **Deployment**: Make changes to the infrastructure by modifying files in this repository, but leave deploying/applying to the user via `./makeItSo.sh`. Avoid manual `kubectl` or `helm` commands for permanent deployment changes.
- **Networking**: Applications are served on subdomains of `fenner.nexus`. This uses a split-horizon DNS setup (no public DNS records) and Nginx Proxy Manager routes requests based on the HTTP `Host` header.
- **Terraform State**: Stored in a private Azure Blob Storage container.

## Logging & Observability (Loki)
- Currently ONLY used to collect pfBlocker-NG DNSBL logs.
- **External URL**: `https://loki.fenner.nexus` (routed via Nginx Proxy Manager; redirects HTTP to HTTPS).
- **In-Cluster URL**: `http://loki.monitoring.svc.cluster.local:3100`
- **Authentication**: Disabled (`auth_enabled: false`).
- **Core Endpoints / API**:
  - Ready check: `GET /ready`
  - Push logs: `POST /loki/api/v1/push` (used by log shippers like Promtail, Fluentbit, syslog-ng)
  - Query instant: `GET /loki/api/v1/query?query=<LogQL>`
  - Query range: `GET /loki/api/v1/query_range?query=<LogQL>&start=<unix_nano>&end=<unix_nano>`
  - Label names: `GET /loki/api/v1/labels`
  - Label values: `GET /loki/api/v1/label/<name>/values`
  - Tail logs (streaming): `GET /loki/api/v1/tail?query=<LogQL>`

## Related Documentation & Reference Files
Consult these markdown documents for deeper context on specific subsystems:
- [README.md](file:///home/mitchfen/Projects/homelab/README.md): High-level homelab architecture, hardware inventory (hostnames, specs, roles), network topology, and DNS/Nginx Proxy Manager setup.
- [BackupPlan.md](file:///home/mitchfen/Projects/homelab/BackupPlan.md): Backup scope, retention policies, Azure storage configuration, and step-by-step bare-metal recovery procedures for Draynor.
- [terraform/README.md](file:///home/mitchfen/Projects/homelab/terraform/README.md): Terraform workflow details, retrieving generated credentials (e.g. Grafana admin password), and upgrading Helm charts.
- [machine specific files/varrock/README.md](file:///home/mitchfen/Projects/homelab/machine%20specific%20files/varrock/README.md): Architecture and operational guide for pfBlockerNG log streaming from pfSense (`dnsbl.log`) directly into Loki via `dnsbl-to-loki.sh` and FreeBSD daemon supervision.


