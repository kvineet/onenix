{ pkgs, mypkgs, config, ... }: {
  home = {
    packages = with pkgs;
      [
        devenv
      ];
    };
}
