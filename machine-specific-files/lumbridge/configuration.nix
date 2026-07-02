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

  programs.fish.enable = true;

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

  virtualisation.docker.enable = true;

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
  ];

  networking.firewall.enable = false;

  system.stateVersion = "25.11"; 
}
