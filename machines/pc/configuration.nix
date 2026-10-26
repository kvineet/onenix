# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, globals, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.kernelModules = [
    "amdgpu"
    "uinput"
  ];
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        gamescope # Virtual micro-compositor for running games headlessly
        pipewire # Low-latency audio capture
        rocmPackages.clr.icd
      ];
    };
    bluetooth = {
      enable = true;
    };
  };
  # hardware.graphics.extraPackages32 = with pkgs; [
  #   driversi686Linux.amdvlk
  # ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;

      publish = {
        enable = true;
        addresses = true;
        domain = true;
        userServices = true;
      };
    };
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    flatpak.enable = true;
    joycond.enable = true;
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
    sonarr = {
      enable = false;
      openFirewall = true;
      user = "${globals.username}";
      group = "users";
      dataDir = "${globals.dirs.downloads}";
    };
    prowlarr = {
      enable = false;
      openFirewall = true;
    };
    transmission = {
      package = pkgs.transmission_4;
      enable = false; # Enable transmission daemon
      openRPCPort = true; # Open firewall for RPC
      settings = {
        # Override default settings
        rpc-bind-address = "0.0.0.0"; # Bind to own IP
        rpc-whitelist = "127.0.0.1"; # Whitelist your remote machine (10.0.0.1 in this example)
      };
    };
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
      xkb = {
        layout = "in";
        variant = "eng";
      };
    };
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # Needed for KMS/screen capture permissions
      openFirewall = true; # Automatically opens UDP/TCP ports 47984-48010
    };
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  systemd.user.services.sunshine = {
    serviceConfig = {
      NoNewPrivileges = false;
      ProtectSystem = false;
      ProtectHome = false;
      PrivateTmp = false;

      # Ensure system environment PATH is inherited
      Environment = [
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
        "QT_QPA_PLATFORM=offscreen"
      ];
    };
  };

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # Enable CUPS to print documents.

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs = {
    firefox.enable = true;
    kdeconnect.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      SDL_VIDEODRIVER = "wayland,x11";
    };
    systemPackages = with pkgs; [
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
      git
      clinfo
      kdePackages.yakuake
      lact
      fusee-nano
      (retroarch.withCores (
        cores: with cores; [
          nestopia
          bsnes-mercury-balanced
          dosbox-pure
        ]
      ))
      linuxPackages.v4l2loopback
      v4l-utils
      gopro-tool
      # retroarch-full
      podman-compose
      ums
      kdePackages.partitionmanager
      soundwireserver
    ];
  };

  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/${globals.username} 0644 root root -"
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  #virtualisation.virtualbox.host.enable = true;
  #users.extraGroups.vboxusers.members = [ "${globals.username}" ];
  #virtualisation.virtualbox.host.enableExtensionPack = true;
  #virtualisation.virtualbox.guest.enable = true;
  #virtualisation.virtualbox.guest.dragAndDrop = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Creates a symlink from docker to podman
    defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  networking = {
    hostName = "kvpc"; # Define your hostname.
    # Enable networking
    networkmanager.enable = true;
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      8465
      5001
      9001
    ];
    firewall.allowedUDPPorts = [
      8554
      1900
      5353 # mDNS
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
