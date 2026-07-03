{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking configuration
  networking.hostName = "rimmington"; # Define your hostname.
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

  # Define a user account
  users.users.mitchfen = {
    isNormalUser = true;
    description = "mitchfen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Default editor settings
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    k3s
    kubernetes-helm
    btop
    lf
    screenfetch
  ];

  # Configure k3s agent systemd service to connect to the main node
  systemd.services.k3s-agent = {
    description = "k3s agent";

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.k3s}/bin/k3s agent";
      Environment = [
        "K3S_TOKEN=REDACTED"
        "K3S_URL=https://draynor:6443"
      ];
      Restart = "on-failure";
      RestartSec = 10;     };

    wantedBy = [ "multi-user.target" ];
  };


  # Enable the OpenSSH daemon
  services.openssh.enable = true;
  
  # Disable the firewall
  networking.firewall.enable = false;

  # Do not change
  system.stateVersion = "25.05";
}
