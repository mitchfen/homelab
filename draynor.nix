{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  fileSystems."/" = {
  options = [ "noatime" ];
  };

  services.journald.extraConfig = "Storage=volatile";

  nix.settings.auto-optimise-store = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "draynor"; # Define your hostname.
  networking.networkmanager.enable = true;
  time.timeZone = "America/Detroit";
  i18n.defaultLocale = "en_US.UTF-8";

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

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.mitchfen = {
    isNormalUser = true;
    description = "mitchfen";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.powershell;
    packages = with pkgs; [];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  environment.systemPackages = with pkgs; [
    k3s
    kubernetes-helm
    btop
    powershell
    lf
    screenfetch
  ];

  systemd.services.k3s-server = {
    description = "k3s server";

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.k3s}/bin/k3s server --disable traefik";
      Restart = "on-failure";
      RestartSec = 10;     };

    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers.k3s-backup = {
    description = "K3s Cluster Backup Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
    };
  };

  systemd.services.k3s-backup = {
    description = "K3s Cluster Backup";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/home/mitchfen/backup-k3s.sh";
      User = "root";
    };
  };


  services.openssh.enable = true;
  networking.firewall.enable = false;

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}

