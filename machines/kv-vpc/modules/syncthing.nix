{ ... }:

{
  services.syncthing = {
    enable = true;
    user = "kvineet";
    group = "users";
    dataDir = "/home/kvineet";
    configDir = "/home/kvineet/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true;
    overrideDevices = false;
    overrideFolders = false;
    settings.options.urAccepted = -1;
  };
}
