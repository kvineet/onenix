{
  pkgs,
  config,
  globals,
  ...
}:
{
  imports = [ ./git-abbr.nix ];
  home = {
    packages = with pkgs; [
      git-credential-manager
      pass
    ];
    sessionVariables = {
      PASSWORD_STORE_DIR = "${config.xdg.configHome}/pass";
    };
  };
  programs.git.enable = true;
  programs.git.delta.enable = true;
}
