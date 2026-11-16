{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [
        "amdgpu"
        "uinput"
      ];
    };
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [
      "kvm-amd"
      "v4l2loopback"
    ];
    extraModulePackages = [
      pkgs.linuxPackages_latest.v4l2loopback
    ];
    supportedFilesystems = [ "nfs" ];
  };

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

  fileSystems = {
    "/mnt/nas" = {
      device = "192.168.68.113:/nas";
      fsType = "nfs4";
      options = [
        "rw"
        "vers=4.1"
        "_netdev"
        "noauto"
        "nofail"
        "x-systemd.automount"
        "x-systemd.idle-timeout=10min"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
