# Agent Context for Homelab

## Environment Details
- **Current Host**: You are always running on `Lumbridge`.
- **Remote Access**: You can SSH into `draynor` and other hosts using username `mitchfen` via SSH key.
- **Tooling**: `terraform` and `kubectl` contexts are already configured and ready to use. You are welcome to run any read-only, inspection, or non-destructive commands (e.g., `terraform plan`, `terraform fmt`, `kubectl get`, `kubectl describe`, `kubectl logs`, etc.).
- **Draynor Host**: Runs Kubernetes (k3s) on NixOS and hosts most applications.
- **Lumbridge Host**: Your local dev machine (where I run), which also hosts local AI models.

## Architecture & Deployment
- **Deployment**: Make changes to the infrastructure by modifying files in this repository, but leave deploying/applying to the user via `./makeItSo.sh`. Avoid manual `kubectl` or `helm` commands for permanent deployment changes.
- **Networking**: Applications are served on subdomains of `fenner.nexus`. This uses a split-horizon DNS setup (no public DNS records) and Nginx Proxy Manager routes requests based on the HTTP `Host` header.
- **Terraform State**: Stored in a private Azure Blob Storage container.

## Further reading
Load all README.md files in this repo in your initial context