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
