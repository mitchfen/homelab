# Backup plan

## What is backed up

- On Draynor, `machine specific files/draynor/backup-k3s.sh` creates a K3s backup in `/var/backups/k3s`. Each archive includes an etcd snapshot, exported cluster objects, and local persistent-volume data.
- Copy the finished `.tar.gz` archives **off Draynor**. The local script retains only seven days, so it is not enough protection against a failed Draynor disk.
- Treat the archives as sensitive: exported Kubernetes secrets and Nginx Proxy Manager data may contain credentials and TLS material. Store the off-machine copy in an encrypted, access-controlled location.

## Regular procedure

1. After important cluster or application changes, log in to Draynor and run:

   ```bash
   sudo bash ~/backup-k3s.sh
   ```

2. Confirm the script reports success and a new archive exists:

   ```bash
   sudo ls -lh /var/backups/k3s/*.tar.gz
   ```

3. Copy the newest archive to the encrypted off-machine backup location. Keep at least several dated copies there; do not rely on the seven-day local retention.

## Restoring Draynor and K3s

Use this for a replacement Draynor machine or a complete cluster recovery.

1. Install NixOS, copy `machine specific files/draynor/configuration.nix` into `/etc/nixos/configuration.nix`, and run:

   ```bash
   sudo nixos-rebuild switch
   ```

2. Copy the chosen backup archive from the off-machine location to Draynor. Unpack it somewhere with enough free space:

   ```bash
   sudo mkdir -p /restore/k3s
   sudo tar -xzf /path/to/YYYY-MM-DD_HH-MM-SS.tar.gz -C /restore/k3s
   ```

3. Stop K3s and restore the etcd snapshot. Replace the snapshot path with the file inside the unpacked archive:

   ```bash
   sudo systemctl stop k3s
   sudo k3s server --cluster-reset --cluster-reset-restore-path=/restore/k3s/YYYY-MM-DD_HH-MM-SS/etcd-snapshots/<snapshot-file>
   ```

4. Restore the local persistent-volume directory before starting K3s. On a replacement host, copy the saved `storage` directory back to `/var/lib/rancher/k3s/` and preserve ownership and permissions:

   ```bash
   sudo cp -a /restore/k3s/YYYY-MM-DD_HH-MM-SS/persistent-volumes/storage /var/lib/rancher/k3s/
   sudo systemctl start k3s
   ```

   If restoring over an existing installation, move its current `storage` directory aside first rather than deleting it.

5. Confirm the cluster and workloads are healthy:

   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

6. If a workload is missing, apply its tracked manifest from this repository. Recreate the landing page with:

   ```bash
   bash landing-page/deploy.sh
   ```

7. Check Nginx Proxy Manager, then test the internal `*.fenner.nexus` sites.
