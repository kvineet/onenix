{ lib, config, ... }:
{
  programs.zsh.zsh-abbr = {
    # This is not lazy, also stupid.
    enable = false;
    abbreviations = {
      "...." = "cd ../../..";
      "-" = "cd -";
      ".." = "cd ..";
      "..." = "cd ../..";
      "_" = "sudo";
      "400" = "chmod 400";
      "600" = "chmod 600";
      "644" = "chmod 644";
      "744" = "chmod 744";
      "x" = "chmod +x";
      "c" = "clear";
      "cd.." = "cd ..";
      "cp" = "cp -i";

      "dot" = "chezmoi";
      ".conf" = "chezmoi apply --exclude scripts";
      ".all" = "chezmoi apply";
      "vault" = "gocryptfs --extpass 'bw get password 3f451323-5391-4568-93da-b0d6000c0740' ~/sync/Vault ~/vault";
      "ag" = "ag --smart-case --pager=\"less -MIRFX\"";
      "cl" = "curl -L";
      "clb" = "curl -L -I";
      "clhead" = "curl -D - -so /dev/null";
      "clo" = "curl -L -O";
      "cloc" = "curl -L -C - -O";
      "clocr" = "curl -L -C - -O --retry 5";
      "cls" = "clear";
      "df" = "df -h";

      "dud" = "du -d 1 -h";
      "duf" = "du -sh *";

      "egrep" = "egrep --colour=auto";
      "epoch" = "date +\"%s%3N\"";
      "fgrep" = "fgrep --colour=auto";
      "free" = "free -m";
      "fsh-alias" = "fast-theme";
      "fuck" = "sudo $(fc -ln -1)";
      "fucking" = "sudo";

      "h" = "history";
      "hcm" = "hg commit -m";
      "hs" = "hg status";
      "hsum" = "hg summary";
      "ipy" = "ipython";
      "irc" = "irssi";
      "k" = "clear";


      "mci" = "mvn clean install";
      "mcisk" = "mvn clean install -Dmaven.test.skip=true";
      "mcp" = "mvn clean package";
      "mcpsk" = "mvn clean package -Dmaven.test.skip=true";
      "md" = "mkdir -p";
      "mdep" = "mvn dependency:tree";
      "mi" = "mvn install";
      "mp" = "mvn package";
      "mpom" = "mvn help:effective-pom";
      "mrperf" = "mvn release:perform";
      "mrprep" = "mvn release:prepare";
      "mrrb" = "mvn release:rollback";

      "more" = "less";

      "myip" = "curl ifconfig.me";
      "pager" = "";
      "pass" = "passgen";
      "path" = "echo -e \${PATH//:/\n}";
      "pco" = "podman-compose";
      "piano" = "pianobar";
      "please" = "sudo $(fc -ln -1)";
      "plz" = "sudo $(fc -ln -1)";
      "plzz" = "sudo $(fc -ln -1)";
      "pm" = "podman";
      "py" = "python";
      "q" = "exit";
      "rb" = "ruby";
      "rd" = "rmdir";
      "rr" = "rm -r";
      "sc" = "systemctl";
      "sce" = "systemctl stop";
      "scr" = "systemctl daemon-reload";
      "scs" = "systemctl start";
      "scu" = "systemctl --user";
      "scue" = "systemctl --user stop";
      "scur" = "systemctl --user daemon-reload";
      "scus" = "systemctl --user start";
      "sl" = "ls";
      "svi" = "sudo nvim";
      "tree" = "find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'";
      "uuid" = "uuidgen | tr '[:upper:]' '[:lower:]'";
      "uuidl" = "uuid";
      "uuidu" = "uuidgen";
      "vbpf" = "vim ~/.bash_profile";
      "vbrc" = "vim ~/.bashrc";
      "vi" = "nvim";
      "which-command" = "whence";
      "xt" = "extract";
    };
  };

  # Lets render our own
  xdg.configFile = {
      "zsh-abbr/user-abbreviations".text = lib.concatStringsSep "\n"
        (lib.mapAttrsToList (k: v: "abbr ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
          config.programs.zsh.zsh-abbr.abbreviations) + "\n";
    };
}
