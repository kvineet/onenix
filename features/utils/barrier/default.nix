{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    packages = with pkgs; [ barrier ];
  };
  xdg.configFile = {
    "barrier/server.conf".text = ''
      section: screens
              kvineet-pc:
                      halfDuplexCapsLock = false
                      halfDuplexNumLock = false
                      halfDuplexScrollLock = false
                      xtestIsXineramaUnaware = false
                      preserveFocus = false
                      switchCorners = none
                      switchCornerSize = 0
              NU-VKULKARNI:
                      halfDuplexCapsLock = false
                      halfDuplexNumLock = false
                      halfDuplexScrollLock = false
                      xtestIsXineramaUnaware = false
                      preserveFocus = false
                      switchCorners = none
                      switchCornerSize = 0
      end

      section: aliases
      end

      section: links
              kvineet-pc:
                      right = NU-VKULKARNI
              NU-VKULKARNI:
                      left = kvineet-pc
      end

      section: options
              relativeMouseMoves = false
              screenSaverSync = true
              win32KeepForeground = false
              clipboardSharing = true
              switchCorners = none
              switchCornerSize = 0
      end
    '';
  };
}
