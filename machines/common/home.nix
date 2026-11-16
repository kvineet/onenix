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
    ../minimal/home.nix
    ../../features/dotetc
    ../../features/emacs
    ../../features/neovim
    ../../features/cloud/cloudflare
    ../../features/cloud/syncthing
    ../../features/cloud/bitwarden
    ../../features/fonts
  ];

  nixpkgs = {
    overlays = [
      # Work around a packaging bug in newer VS Code releases where the
      # ripgrep cleanup path is missing during patchPhase.
      (final: prev: {
        vscode-fhs = prev.vscode-fhs.overrideAttrs (old: {
          postPatch =
            let
              patched = lib.replaceStrings
                [ "rm -rf resources/app/node_modules/@vscode/ripgrep/bin/rg" ]
                [ "rm -rf resources/app/node_modules/@vscode/ripgrep/bin/rg || true" ]
                (old.postPatch or "");
            in
            if builtins.isString (old.postPatch or null) then
              patched
            else
              ""
              + "rm -rf resources/app/node_modules/@vscode/ripgrep/bin/rg || true";
        });
      })
    ];
  };
  home = {
    packages = with pkgs; [
      go
      gh
    ];
  };
  programs.ssh = {
    settings = {
      "github.com-kvineet" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
      "gitlab.com-kvineet" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
      "github.com-engineerwolf" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_engineerwolf";
      };
      "gitlab.com-engineerwolf" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_engineerwolf";
      };
    };
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
