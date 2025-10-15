{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      # ...various
      luajitPackages.luarocks
      lua51Packages.lua
    ];
  xdg.configFile ={
    "nvim/init.lua" = {
      text = ''
      require("config.lazy")'';
    };

    "nvim/lua/config/lazy.lua" = {
      text = ''
      -- Bootstrap lazy.nvim
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
          }, true, {})
          vim.fn.getchar()
          os.exit(1)
        end
      end
      vim.opt.rtp:prepend(lazypath)

      -- Make sure to setup `mapleader` and `maplocalleader` before
      -- loading lazy.nvim so that mappings are correct.
      -- This is also a good place to setup other settings (vim.opt)
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- Setup lazy.nvim
      require("lazy").setup({
        spec = {
          {
            'nvim-orgmode/orgmode',
            event = 'VeryLazy',
            ft = { 'org' },
            config = function()
              -- Setup orgmode
              require('orgmode').setup({
                org_agenda_files = '~/orgfiles/**/*',
                org_default_notes_file = '~/orgfiles/refile.org',
              })

              -- NOTE: If you are using nvim-treesitter with ~ensure_installed = "all"~ option
              -- add ~org~ to ignore_install
              -- require('nvim-treesitter.configs').setup({
              --   ensure_installed = 'all',
              --   ignore_install = { 'org' },
              -- })
            end,
          }
        },
        -- Configure any other settings here. See the documentation for more details.
        -- colorscheme that will be used when installing plugins.
        install = { colorscheme = { "habamax" } },
        -- automatically check for plugin updates
        checker = { enabled = true },
      })'';
    };
    "nvim/lua/plugins/orgmode.lua" = {
      text = ''
      return {
      {
        'nvim-orgmode/orgmode',
        event = 'VeryLazy',
        ft = { 'org' },
        config = function()
          -- Setup orgmode
          require('orgmode').setup({
            org_agenda_files = '~/orgfiles/**/*',
            org_default_notes_file = '~/orgfiles/refile.org',
          })

          -- NOTE: If you are using nvim-treesitter with ~ensure_installed = "all"~ option
          -- add ~org~ to ignore_install
          -- require('nvim-treesitter.configs').setup({
          --   ensure_installed = 'all',
          --   ignore_install = { 'org' },
          -- })
        end,
      }}'';
    };
    
  };
}
