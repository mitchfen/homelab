{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Root file system mount options
  fileSystems."/" = {
  options = [ "noatime" ];
  };

  # Configure journald to use volatile storage (RAM) to reduce disk I/O and limit size
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=50M
  '';

  # Automatically optimize the Nix store to save disk space
  nix.settings.auto-optimise-store = true;

  # Automate garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking configuration
  networking.hostName = "draynor";
  networking.networkmanager.enable = true;
  
  # Set your time zone.
  time.timeZone = "America/Detroit";
  
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Extra locale settings
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Fish shell configuration and aliases
  programs.fish = {
    enable = true;
    shellAliases = {
      nixUpgrade = "sudo nixos-rebuild switch --upgrade";
      nixClean = "sudo nix-collect-garbage -d && sudo k3s crictl rmi --prune";
      nixListGenerations = "sudo nixos-rebuild list-generations";
      k = "kubectl";
      vim = "nvim";

      getK3sConfig = "cat /etc/rancher/k3s/k3s.yaml";
    };
  };

  # Define a user account
  users.users.mitchfen = {
    isNormalUser = true;
    description = "mitchfen";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    packages = with pkgs; [];

    # Configure with my public SSH key. https://github.com/mitchfen.keys
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGeJggqUriwWRH1VI6k0l7+KCOVaMVMGBY4vGME9jyH" 
    ];
  };

  # Default editor settings
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    k3s
    kubernetes-helm
    btop
    screenfetch
    antigravity-cli
  ];

  # k3s server configuration
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable traefik";
  };

  # Enable the OpenSSH daemon and harden it
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  
  # Configure the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 81 6443 10250 ]; # SSH, Nginx proxy, K3s API, Kubelet
    allowedUDPPorts = [ 8472 ]; # Flannel VXLAN for k3s agents
  };

  # Do not change
  system.stateVersion = "25.05"; 

}

