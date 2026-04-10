{
  config,
  pkgs,
  lib,
  ...
}:
let
  lang = config.my.lang;
  clipboardProvider = config.my.nvim.clipboard.provider;

  fusen-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "fusen.nvim";
    version = "ff57476e167dd5437b6030616b7257e2a3b0619f";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "walkersumida";
      repo = "fusen.nvim";
      rev = "ff57476e167dd5437b6030616b7257e2a3b0619f";
      hash = "sha256-oP1gv76KsFj2QOoWE/Tewm8ueN2bzVYqO40I9vnuPW4=";
    };
  };

  rustowl-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "rustowl";
    version = "84b3f8348815179fb03fa9249f83f6acde059fee";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "cordx56";
      repo = "rustowl";
      rev = "84b3f8348815179fb03fa9249f83f6acde059fee";
      hash = "sha256-2m2RBFwTcZ/FaGGp1asWEV7LKi4J8gcrMZU3Ewy0fgQ=";
    };
  };

  nvim-lsp-file-operations = pkgs.vimUtils.buildVimPlugin {
    pname = "nvim-lsp-file-operations";
    version = "b9c795d3973e8eec22706af14959bc60c579e771";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "antosha417";
      repo = "nvim-lsp-file-operations";
      rev = "b9c795d3973e8eec22706af14959bc60c579e771";
      hash = "sha256-4LugE23xPGpCjqeqNtCbou4RUaUf6TBJ0dNoGhhkx6c=";
    };
  };

  vim-maximizer = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-maximizer";
    version = "2e54952fe91e140a2e69f35f22131219fcd9c5f1";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "szw";
      repo = "vim-maximizer";
      rev = "2e54952fe91e140a2e69f35f22131219fcd9c5f1";
      hash = "sha256-+VPcMn4NuxLRpY1nXz7APaXlRQVZD3Y7SprB/hvNKww=";
    };
  };

  vim-translator = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-translator";
    version = "6f0639c6d471a3a90ac19db96e1e379c030f74e3";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "voldikss";
      repo = "vim-translator";
      rev = "6f0639c6d471a3a90ac19db96e1e379c030f74e3";
      hash = "sha256-ow5axYMtH433hXwYF5Oz3wWT/24VUHpALrH+Phlwk90=";
    };
  };

  vimdoc-ja = pkgs.vimUtils.buildVimPlugin {
    pname = "vimdoc-ja";
    version = "b62e3f2331fec05d7d0a43b25b4daa3e4a71781b";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "vim-jp";
      repo = "vimdoc-ja";
      rev = "b62e3f2331fec05d7d0a43b25b4daa3e4a71781b";
      hash = "sha256-Vy+DYeQ7/Gk9Zh10nDmsD/ikG8na2rZYhbUfatvR+LY=";
    };
  };

  treesitterWithGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    p:
    with p;
    [
      bash
      c
      dockerfile
      gitignore
      json
      lua
      markdown
      markdown_inline
      query
      vim
      vimdoc
      yaml
    ]
    ++ lib.optionals lang.node.enable [
      css
      graphql
      html
      javascript
      prisma
      svelte
      tsx
      typescript
    ]
    ++ lib.optionals lang.nix.enable [ nix ]
    ++ lib.optionals lang.python.enable [ python ]
    ++ lib.optionals lang.ruby.enable [ ruby ]
    ++ lib.optionals lang.rust.enable [ rust ]
  );

  luaBool = value: if value then "true" else "false";
in
{
  options.my.nvim.clipboard.provider = lib.mkOption {
    type = lib.types.enum [
      "auto"
      "wayland"
      "xclip"
      "none"
    ];
    default = "auto";
    description = "Neovim clipboard provider to configure on this host.";
  };

  config.programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = ",";
      netrw_liststyle = 3;
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
      translator_target_lang = "ja";
      translator_default_engines = [ "google" ];
    }
    // lib.optionalAttrs lang.latex.enable {
      vimtex_view_method = "zathura";
      vimtex_compiler_latexmk = {
        out_dir = "out";
        aux_dir = "out";
      };
    };

    opts = {
      relativenumber = true;
      number = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      autoindent = true;
      wrap = false;
      ignorecase = true;
      smartcase = true;
      cursorline = true;
      termguicolors = true;
      background = "dark";
      signcolumn = "yes";
      backspace = "indent,eol,start";
      splitright = true;
      splitbelow = true;
      helplang = "ja,en";
      updatetime = 1000;
      timeout = true;
      timeoutlen = 500;
    }
    // lib.optionalAttrs (clipboardProvider != "none") {
      clipboard = "unnamedplus";
    };

    extraPackages =
      with pkgs;
      [
        lua-language-server
        typos-lsp
        stylua
      ]
      ++ lib.optionals (builtins.elem clipboardProvider [
        "auto"
        "wayland"
      ]) [ wl-clipboard ]
      ++ lib.optionals (builtins.elem clipboardProvider [
        "auto"
        "xclip"
      ]) [ xclip ]
      ++ lib.optionals lang.node.enable [
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted
        tailwindcss-language-server
        nodePackages.graphql-language-service-cli
        emmet-language-server
        prisma-language-server
        nodePackages.prettier
        eslint_d
      ]
      ++ lib.optionals lang.nix.enable [
        nil
        nixfmt-rfc-style
      ]
      ++ lib.optionals lang.python.enable [
        pyright
        black
        isort
        pylint
      ]
      ++ lib.optionals lang.ruby.enable [
        solargraph
        rubyPackages.ruby-lsp
        rubyPackages.htmlbeautifier
      ]
      ++ lib.optionals lang.latex.enable [ texlivePackages.latexindent ]
      ++ lib.optionals lang.rust.enable [ rustfmt ];

    extraPlugins =
      with pkgs.vimPlugins;
      [
        plenary-nvim
        vim-tmux-navigator
        alpha-nvim
        nvim-web-devicons
        auto-session
        nvim-autopairs
        nvim-cmp
        cmp-buffer
        cmp-path
        luasnip
        cmp_luasnip
        friendly-snippets
        lspkind-nvim
        bufferline-nvim
        tokyonight-nvim
        copilot-vim
        nvim-dap
        nvim-dap-ui
        nvim-nio
        nvim-dap-virtual-text
        diffview-nvim
        dressing-nvim
        conform-nvim
        fusen-nvim
        gitsigns-nvim
        indent-blankline-nvim
        nvim-lint
        lualine-nvim
        markview-nvim
        nvim-neoclip-lua
        sqlite-lua
        nvim-tree-lua
        substitute-nvim
        nvim-surround
        telescope-nvim
        telescope-fzf-native-nvim
        todo-comments-nvim
        toggleterm-nvim
        treesitterWithGrammars
        nvim-ts-autotag
        trouble-nvim
        vim-maximizer
        vim-translator
        vimdoc-ja
        which-key-nvim
        nvim-lspconfig
        cmp-nvim-lsp
        nvim-lsp-file-operations
        neodev-nvim
      ]
      ++ lib.optionals lang.latex.enable [ vimtex ]
      ++ lib.optionals lang.lean.enable [ lean-nvim ]
      ++ lib.optionals lang.rust.enable [
        neotest
        FixCursorHold-nvim
        rustowl-nvim
        rustaceanvim
      ];

    extraConfigLua =
      builtins.replaceStrings
        [
          "@TYPOS_CONFIG@"
          "@CLIPBOARD_PROVIDER@"
        ]
        [
          "${./nixvim/typos.toml}"
          clipboardProvider
        ]
        (
          builtins.replaceStrings
            [
              "@LANG_NODE_ENABLED@"
              "@LANG_PYTHON_ENABLED@"
              "@LANG_RUST_ENABLED@"
              "@LANG_LATEX_ENABLED@"
              "@LANG_NIX_ENABLED@"
              "@LANG_RUBY_ENABLED@"
              "@LANG_LEAN_ENABLED@"
            ]
            [
              (luaBool lang.node.enable)
              (luaBool lang.python.enable)
              (luaBool lang.rust.enable)
              (luaBool lang.latex.enable)
              (luaBool lang.nix.enable)
              (luaBool lang.ruby.enable)
              (luaBool lang.lean.enable)
            ]
            (builtins.readFile ./nixvim/config.lua)
        );
  };
}
