#!/bin/bash
# K3s Cluster Backup Script for Draynor (NixOS)
# Backs up etcd snapshots and persistent volume data
# Usage: ./backup-k3s.sh

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backups/k3s"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"
K3S_DATA_DIR="/var/lib/rancher/k3s"
LOG_FILE="${BACKUP_DIR}/backup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Error handler
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Create backup directory structure
mkdir -p "$BACKUP_PATH"
mkdir -p "${BACKUP_DIR}/logs"

log "INFO" "Starting K3s backup to $BACKUP_PATH"

# Backup 1: K3s etcd snapshot
log "INFO" "Backing up etcd..."
if ! k3s etcd-snapshot save --dir "${BACKUP_PATH}/etcd-snapshots" 2>&1 | tee -a "$LOG_FILE"; then
    error_exit "Failed to create etcd snapshot"
fi
log "INFO" "✓ Etcd snapshot created"

# Backup 2: Export all Kubernetes manifests from all namespaces
log "INFO" "Exporting Kubernetes manifests..."
mkdir -p "${BACKUP_PATH}/manifests"
for namespace in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
    log "INFO" "  - Exporting namespace: $namespace"
    kubectl get all,configmap,secret,pvc,persistentvolume -n "$namespace" -o yaml > "${BACKUP_PATH}/manifests/${namespace}.yaml"
done
log "INFO" "✓ Manifests exported"

# Backup 3: Backup persistent volume data
log "INFO" "Backing up persistent volumes..."
PVC_DATA_DIR="${BACKUP_PATH}/persistent-volumes"
mkdir -p "$PVC_DATA_DIR"

# Get local path provisioner data directory (default for k3s)
LOCAL_PATH_DIR="${K3S_DATA_DIR}/storage"
if [ -d "$LOCAL_PATH_DIR" ]; then
    log "INFO" "  - Copying local path storage..."
    cp -r "$LOCAL_PATH_DIR" "${PVC_DATA_DIR}/" 2>&1 | tee -a "$LOG_FILE" || {
        log "WARN" "Could not backup all PV data (may require elevated permissions)"
    }
    log "INFO" "✓ Persistent volumes backed up"
else
    log "WARN" "Local path storage directory not found at $LOCAL_PATH_DIR"
fi

# Backup 4: Cluster info and configuration
log "INFO" "Saving cluster information..."
kubectl cluster-info > "${BACKUP_PATH}/cluster-info.txt" 2>&1
kubectl get nodes -o yaml > "${BACKUP_PATH}/nodes.yaml"
kubectl top nodes > "${BACKUP_PATH}/node-resources.txt" 2>&1 || log "WARN" "Could not get node resources"

log "INFO" "✓ Cluster information saved"

# Create tar archive
log "INFO" "Creating compressed archive..."
tar -czf "${BACKUP_PATH}.tar.gz" -C "$BACKUP_DIR" "$TIMESTAMP" 2>&1 | tee -a "$LOG_FILE"
rm -rf "$BACKUP_PATH"
log "INFO" "✓ Archive created: ${BACKUP_PATH}.tar.gz"

# Cleanup old backups
log "INFO" "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
REMAINING=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" -type f | wc -l)
log "INFO" "✓ Cleanup complete. $REMAINING backups retained."

# Summary
log "INFO" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "INFO" "Backup completed successfully!"
log "INFO" "Backup location: ${BACKUP_PATH}.tar.gz"
log "INFO" "Backup size: $(du -sh "${BACKUP_PATH}.tar.gz" | cut -f1)"
log "INFO" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
