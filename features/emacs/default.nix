{
  pkgs,
  config,
  ...
}:
let
  myEmacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (
    epkgs: with pkgs; [
      epkgs.nerd-icons
      tree-sitter
      tree-sitter-grammars.tree-sitter-nix
      epkgs.vterm
    ]
  );
in
{
  imports = [
    ./chemacs2.nix
    ./doom.nix
  ];
  programs.emacs.enable = false;
  services.emacs.enable = true;
  home = {
    packages = with pkgs; [
      # ...various
      (ripgrep.override { withPCRE2 = true; })
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      aspellDicts.hi
      aspellDicts.mr
      auctex
      binutils
      cargo
      csharpier
      dockfmt
      editorconfig-core-c
      emacs-all-the-icons-fonts
      fd
      gnutls
      gcc
      gnuplot
      gomodifytags
      gopls
      gore
      gotests
      gotools
      imagemagick
      maim
      math-preview
      nil
      nixd
      nodejs
      nixfmt-rfc-style
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.iosevka-term-slab
      nerd-fonts.caskaydia-cove
      nerd-fonts.symbols-only
      rust-analyzer
      rustc
      shfmt
      sqlite
      texliveFull
      wl-clipboard
      xclip
      zstd

      myEmacs
    ];
    sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

  };
  programs.zsh.zsh-abbr.abbreviations = {
    "e" = "emacsclient -n";
    "E" = "SUDO_EDITOR=emacsclient sudo -e";
    "ed" = "emacs --daemon";
    "em" = "emacs";
    "en" = "emacs -nw";
    "et" = "emacsclient -t";
  };
  xdg.configFile = {
    emacsServiceOverride = {
      target = "systemd/user/emacs.service.d/override.conf";
      text = ''
        [Unit]
        After=graphical-session.target

        [Install]
        WantedBy=
        WantedBy=graphical-session.target
      '';
    };
  };
  xdg.dataFile = {
    "applications/org-protocol.desktop".text = ''
      [Desktop Entry]
      Name=org-protocol
      Comment=Intercept calls from emacsclient to trigger custom actions
      Categories=Other;
      Keywords=org-protocol;
      Icon=emacs
      Type=Application
      Exec=emacsclient %u
      Terminal=false
      StartupWMClass=Emacs
      MimeType=x-scheme-handler/org-protocol;
    '';
  };
}
