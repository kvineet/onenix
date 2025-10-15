{ config, lib, pkgs, ... }: {
  home.activation.chemacs2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    REPO_URL=https://github.com/plexus/chemacs2.git
    REPO_PATH="${config.xdg.configHome}/emacs"
    REPO_NAME="chemacs2"
    if [ -d "$REPO_PATH" ]; then
       echo "$REPO_NAME exists. Pulling latest..."
       $DRY_RUN_CMD ${lib.getExe pkgs.git} -C "$REPO_PATH" $VERBOSE_ARG pull
    else
       echo "$REPO_NAME does not exist. Cloning..."
       $DRY_RUN_CMD ${lib.getExe pkgs.git} clone $VERBOSE_ARG \
                    --depth=1 --single-branch \
                    "$REPO_URL" \
                    "$REPO_PATH"
    fi
    echo "done."
    '';
  xdg.configFile ={
    "chemacs/profiles.el".text = ''
    (("default" . ((user-emacs-directory . "~/.config/doom.emacs")
                  (env . (("DOOMDIR" . "~/.config/doom")))
    ))
    )'';
  };
}
