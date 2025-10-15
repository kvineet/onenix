{ ... }: {
  programs.lsd.enable = true;
  programs.zsh.zsh-abbr.abbreviations = {
    "l" = "lsd -a";
    "l1" = "lsd -1";
    "la" = "lsd -AF";
    "ll" = "lsd -lah";
    "ls" = "lsd";
    "lt" = "lsd --tree";
  };
}
