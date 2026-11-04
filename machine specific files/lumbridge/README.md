# Lumbridge NixOS Configuration

Lumbridge runs NixOS configured with a hybrid channel setup combining the stable channel (`nixos`) for baseline OS stability and the `unstable` channel (`nixos-unstable`) for rapidly updated developer tools and desktop software.

---

## Channel Setup & Management

Because Nix evaluates `<unstable>` via NIX_PATH, the channel must exist in root's channel list.

### 1. View Current Channels
```bash
sudo nix-channel --list
```
Expected output:
```text
nixos https://nixos.org/channels/nixos-2x.xx
unstable https://nixos.org/channels/nixos-unstable
```

### 2. Adding the Unstable Channel (if setting up fresh)
```bash
sudo nix-channel --add https://nixos.org/channels/nixos-unstable unstable
sudo nix-channel --update
```

### 3. Updating & Rebuilding
- **Update all channels and rebuild:**
  ```bash
  sudo nixos-rebuild switch --upgrade
  ```
  *(Or use the fish alias: `nixUpgrade`)*

- **Update channels only:**
  ```bash
  sudo nix-channel --update
  ```

---

## How It Works in `configuration.nix`

### Importing Unstable
At the top of [`configuration.nix`](./configuration.nix):

```nix
let
  unstable = import <unstable> { config = config.nixpkgs.config; };
in
{
  ...
}
```

> [!NOTE]
> Passing `{ config = config.nixpkgs.config; }` ensures that flags like `nixpkgs.config.allowUnfree = true` apply to packages installed from the unstable channel as well.

### Installing Packages
Install stable packages through `pkgs` and append unstable packages through `unstable`:

```nix
environment.systemPackages = (with pkgs; [
  git
  gh
  kubectl
  # ... other stable packages
]) ++ [
  unstable.antigravity-ide
  unstable.antigravity-cli
  unstable.protonmail-desktop
  unstable.proton-pass
  unstable.proton-vpn
  unstable.lmstudio
];
```

---

## Quick Reference / Tips

- **Searching unstable packages locally:**
  ```bash
  nix-env -qaP -f '<unstable>' <package_name>
  ```
- **Checking channel paths:** Root channels are symlinked at `/nix/var/nix/profiles/per-user/root/channels`.
