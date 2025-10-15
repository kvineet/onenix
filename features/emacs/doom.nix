{
  config,
  lib,
  pkgs,
  ...
}:
{
  # TODO: this script can be templated
  home = {
    activation.doom-emacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      REPO_URL=https://github.com/doomemacs/doomemacs.git
      REPO_PATH="${config.xdg.configHome}/doom.emacs"
      REPO_NAME="doom emacs"
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
    sessionPath = [ "${config.xdg.configHome}/doom.emacs/bin" ];
  };
}
