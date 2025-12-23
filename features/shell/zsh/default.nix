{
  pkgs,
  config,
  lib,
  globals,
  ...
}:
{
  imports = [ ./zsh-abbr/default.nix ];
  xdg.dataFile = {
    "zinit/zinit.git".source = builtins.fetchGit {
      url = "https://github.com/zdharma-continuum/zinit.git";
      ref = "v3.14.0";
      allRefs = true;
      rev = "5c0c0454deeb9eac95e08ef214b5d7ba6859db14";
    };
  };
  xdg.configFile.p10k = {
    target = "zsh/.p10k.zsh";
    source = ./p10k.zsh;
  };
  home = {
    packages = with pkgs; [
      zsh
      python3Full
      zinit
    ];
    sessionVariables = {
      NIX_PATH = "${config.xdg.stateHome}/nix/defexpr/channels";
    };
  };
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    initContent = builtins.readFile ./zshrc;
  };
  # For some reason home manager imports "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
  # but our nix profile directory is in "${config.xdg.stateHome}/nix/profile/etc/profile.d/hm-session-vars.sh"
  # hence the mkForce

  # home.file.".config/zsh/.zshenv".text = lib.mkForce ''
  #   # Environment variables
  #   . "${config.xdg.stateHome}/nix/profile/etc/profile.d/hm-session-vars.sh"

  #   # Only source this once
  #   if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
  #      export __HM_ZSH_SESS_VARS_SOURCED=1
  #   fi
  #   export ZDOTDIR=$HOME/'.config/zsh'
  # '';
}
