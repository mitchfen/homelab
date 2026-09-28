# Backup Plan

## Goal

Recover my homelab after loss of Draynor without relying on a copy of its disk. The desired configuration lives in this repository and Terraform state; backups protect the data that cannot be recreated from those sources.

## Sources of truth

| Source | Protects | Recovery use |
| --- | --- | --- |
| This Git repository | NixOS configuration, Kubernetes manifests, Terraform, and landing-page content | Rebuilds the desired machine and workload configuration |
| Azure Blob backup | Application data, Nginx Proxy Manager data, certificates, and unmanaged credentials | Restores data that Git and Terraform do not contain |
| Azure Blob Terraform state | Terraform's record of managed Kubernetes resources | Allows Terraform to continue managing the restored cluster |

## Backup Scope

Back up these Draynor paths to the `backups` container in the existing `mitchfenner` Azure Storage account. Azure Storage encrypts blobs at rest.

| Path | Contents | Why it is backed up |
| --- | --- | --- |
| `/var/lib/rancher/k3s/server/` | k3s datastore, server token, and control-plane data | Preserves Kubernetes object identities, datastore encryption data, and cluster configuration |
| `/var/lib/rancher/k3s/storage/` | Local-path PVC data (excluding ephemeral monitoring PVCs: Loki, Prometheus, Grafana) | Preserves persistent local-path volume data without bloating archives with operational telemetry |
| `/var/lib/npm/` | Nginx Proxy Manager data, proxy-host configuration, and TLS certificates | Preserves all Nginx Proxy Manager state |
| `/var/lib/weighttracker/` | Weight Tracker SQLite database | Preserves weight records independently of Kubernetes PVCs |
| `/var/lib/bptracker/` | Blood Pressure Tracker SQLite database | Preserves blood-pressure records independently of Kubernetes PVCs |

The k3s datastore backup contains Kubernetes Secrets, including the unmanaged `nanoleaf-secrets` Secret. Restrict access to the Azure backup container accordingly. Restoring the datastore restores that Secret.

## Backup Method

The backup process runs on Draynor because only Draynor can read the host paths above. `kubectl` from another machine can help inspect Kubernetes resources, but it cannot back up Nginx Proxy Manager host-path data or the k3s datastore.

Run `machine specific files/draynor/backup-to-azure.sh` with `sudo` after authenticating to Azure CLI as the normal Draynor user. The script briefly stops k3s, archives the k3s datastore and persistent host paths, restarts k3s, and uploads the archive to `backups/draynor/`. The logged-in identity needs the Storage Blob Data Contributor role on the storage account.

The implementation should:

1. Run manually after important changes until an unattended Azure identity is configured. A systemd timer requires a non-interactive identity with Storage Blob Data Contributor access.
2. Use Azure Storage encryption at rest and keep Azure access controlled.
3. Retain daily backups for 30 days, monthly backups for 12 months, and at least one yearly backup.
4. Alert or write a durable log when a backup fails.
5. Run regular repository checks or restore verification.

The backup container must use retention or lifecycle rules so dated backups are not removed accidentally.

## Recovery Procedure

1. Install NixOS.
2. Restore the tracked Draynor NixOS configuration, including its machine-specific hardware configuration, then run `nixos-rebuild switch`.
3. Stop k3s:
   ```bash
   sudo systemctl stop k3s
   ```
4. Download the backup archive from Azure Blob Storage and extract it directly into `/` (the archive stores paths relative to root: `var/lib/rancher/k3s/...`, `var/lib/npm/...`, etc.):
   ```bash
   az storage blob download \
     --account-name mitchfenner \
     --container-name backups \
     --name "draynor/draynor.tar.gz" \
     --file draynor.tar.gz \
     --auth-mode login

   sudo tar -xzvf draynor.tar.gz -C /
   ```
5. Start k3s and confirm its workloads recover from the restored datastore:
   ```bash
   sudo systemctl start k3s
   ```
6. On Lumbridge, clone this repository, authenticate to Azure and the restored k3s cluster, then run `terraform init` and `terraform apply` to reconcile the managed configuration.
7. Verify application data, Nginx Proxy Manager proxy hosts and certificates, and the internal sites.
