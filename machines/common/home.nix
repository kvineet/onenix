{
  inputs,
  lib,
  config,
  pkgs,
  globals,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    ../../features/dotetc
    ../../features/shell
    ../../features/emacs
    ../../features/neovim
    ../../features/cloud/cloudflare
    ../../features/cloud/syncthing
    ../../features/cloud/bitwarden
    ../../features/fonts
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "${globals.username}";
    homeDirectory = "/home/${globals.username}";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # Enable home-manager
  programs.home-manager.enable = true;
  home = {
    stateVersion = "23.05";
    packages = with pkgs; [
      rar
      fzf
      jq
      yq-go
      go
      gh
    ];
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host github.com-kvineet
           HostName github.com
           User git
           IdentityFile ~/.ssh/id_ed25519
      Host gitlab.com-kvineet
           HostName gitlab.com
           User git
           IdentityFile ~/.ssh/id_ed25519
      Host github.com-engineerwolf
           HostName github.com
           User git
           IdentityFile ~/.ssh/id_engineerwolf
      Host gitlab.com-engineerwolf
           HostName gitlab.com
           User git
           IdentityFile ~/.ssh/id_engineerwolf
    '';
  };
  programs.git.includes = [
    {
      condition = "hasconfig:remote.*.url:https://git*.com/kvineet/**";
      contentSuffix = "kvineet.gitconfig";
      contents = {
        user = {
          email = "vineet.kulkarni8@gmail.com";
          name = "Vineet Kulkarni";
        };
        url = {
          "ssh://git@github.com-kvineet/" = {
            insteadOf = "https://github.com/";
          };
          "ssh://git@gitlab.com-kvineet/" = {
            insteadOf = "https://gitlab.com/";
          };
        };
      };
    }
    {
      condition = "hasconfig:remote.*.url:https://git*.com/engineerwolf/**";
      contentSuffix = "engineerwolf.gitconfig";
      contents = {
        user = {
          email = "engineerwolf.reddit@gmail.com";
          name = "Engineerwolf";
        };
        url = {
          "ssh://git@github.com-engineerwof/" = {
            insteadOf = "https://github.com/";
          };
          "ssh://git@gitlab.com-engineerwolf/" = {
            insteadOf = "https://gitlab.com/";
          };
        };
      };
    }
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
