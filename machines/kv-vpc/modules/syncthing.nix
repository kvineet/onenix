{ globals, ... }:

{
  services.syncthing = {
    enable = true;
    user = "${globals.username}";
    group = "users";
    dataDir = "/home/${globals.username}";
    configDir = "/home/${globals.username}/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true;
    overrideDevices = false;
    overrideFolders = false;
    settings.options.urAccepted = -1;
  };
}
