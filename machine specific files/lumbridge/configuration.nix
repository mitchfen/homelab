# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Root file system mount options
  fileSystems."/" = {
    options = [ "noatime" ];
  };

  # Configure journald to use volatile storage (RAM) to reduce disk I/O
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

  # Define your hostname
  networking.hostName = "lumbridge"; 

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Detroit";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment (Updated paths to fix warnings).
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- GNOME PACKAGE CLEANUP ---
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit
  ]) ++ (with pkgs; [
    cheese
    gnome-music
    epiphany
    geary
    evince
    gnome-characters
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-software
    yelp
    tali
    iagno
    hitori
    atomix
  ]);

  # --- DEFAULT EDITOR SETTINGS ---
  # This makes nvim the system default and aliases vi/vim to it.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Fish shell configuration and aliases
  programs.fish = {
    enable = true;
    shellAliases = {
      nixUpgrade = "sudo nixos-rebuild switch --upgrade";
      nixClean = "sudo nix-collect-garbage -d";
      nixListGenerations = "sudo nixos-rebuild list-generations";
      k = "kubectl";
      vim = "nvim";
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account.
  users.users.mitchfen = {
    isNormalUser = true;
    description = "mitchfen";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish; 
    packages = with pkgs; [
      # User specific packages can go here
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Docker and auto-pruning
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    google-chrome
    firefox 
    gnome-tweaks
    vlc
    screenfetch
    proton-pass
    antigravity
    gthumb
    git
    gh
    go
    gcc
    nodejs_latest
    btop
    lmstudio
    kubernetes-helm
    kubectl
    k9s
    runelite
    antigravity-cli
    lf
  ];

  # Configure the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 1234 ]; # LMStudio
  };

  # Do not change
  system.stateVersion = "25.11"; 
}
