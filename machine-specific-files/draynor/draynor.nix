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
    packages = with pkgs; [];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    k3s
    kubernetes-helm
    btop
    lf
    screenfetch
  ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable traefik";
  };

  environment.shellAliases = {
    k = "kubectl";
    vim = "nvim";
  };

  services.openssh.enable = true;
  networking.firewall.enable = false;

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}