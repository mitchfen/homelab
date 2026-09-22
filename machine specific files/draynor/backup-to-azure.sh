#!/usr/bin/env bash
set -euo pipefail

STORAGE_ACCOUNT="mitchfenner"
CONTAINER="backups"
BACKUP_USER="${SUDO_USER:-$USER}"
# Blob versioning is enabled on the storage account, so we always upload under
# the same blob name; Azure keeps prior uploads as versions instead of us
# needing timestamped filenames.
ARCHIVE_NAME="draynor.tar.gz"
WORK_DIR="$(mktemp --directory)"
ARCHIVE_PATH="${WORK_DIR}/${ARCHIVE_NAME}"
K3S_STOPPED=false

cleanup() {
  if [[ "$K3S_STOPPED" == true ]]; then
    echo "Restarting k3s..."
    systemctl start k3s
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if [[ "$EUID" -ne 0 ]]; then
  echo "Run this script with sudo so it can read Draynor's persistent data." >&2
  exit 1
fi

if ! id "$BACKUP_USER" &>/dev/null; then
  echo "Azure CLI user '$BACKUP_USER' does not exist." >&2
  exit 1
fi

echo "Creating ${ARCHIVE_NAME}..."
echo "Stopping k3s to create a consistent datastore and persistent-data backup..."
systemctl stop k3s
K3S_STOPPED=true

tar --create --gzip --file "$ARCHIVE_PATH" --directory / \
  var/lib/rancher/k3s/server \
  var/lib/rancher/k3s/storage \
  var/lib/npm \
  var/lib/weighttracker \
  var/lib/caroline-tracker \
  var/lib/bptracker

echo "Restarting k3s..."
systemctl start k3s
K3S_STOPPED=false

chown "$BACKUP_USER" "$WORK_DIR" "$ARCHIVE_PATH"

echo "Verifying Azure CLI authentication for ${BACKUP_USER}..."
sudo -u "$BACKUP_USER" az account show --only-show-errors --output none

echo "Uploading backup to Azure Blob Storage..."
sudo -u "$BACKUP_USER" az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$CONTAINER" \
  --name "draynor/${ARCHIVE_NAME}" \
  --file "$ARCHIVE_PATH" \
  --auth-mode login \
  --overwrite true \
  --tier Cold \
  --content-type application/gzip \
  --only-show-errors \
  --output none

echo "Backup uploaded: backups/draynor/${ARCHIVE_NAME}"