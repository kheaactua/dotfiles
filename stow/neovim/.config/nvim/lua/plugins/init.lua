return {
  -- "folke/neodev.nvim",
  -- "folke/which-key.nvim",
  -- { "folke/neoconf.nvim", cmd = "Neoconf" },
  {
    'tpope/vim-fugitive',
    dependencies = { "tpope/vim-rhubarb" },
    init = function()
      vim.opt.diffopt:append('vertical')
    end,
  },

  -- Navigating the quickfix window better.  Recommended by fugitive
  'tpope/vim-unimpaired',

  -- This should improve Git Fugitive and Git Gutter
  'tmux-plugins/vim-tmux-focus-events',

  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    init = function()
      -- vim.keymap.set({ "i", "s" }, "<C-i>", function() require'luasnip'.jump(1)  end, { desc = "LuaSnip forward jump"  })
      -- vim.keymap.set({ "i", "s" }, "<M-i>", function() require'luasnip'.jump(-1) end, { desc = "LuaSnip backward jump" })

      dotfiles_dir=vim.api.nvim_get_var('dotfiles')
      require("luasnip.loaders.from_snipmate").lazy_load({ paths = { dotfiles_dir .. "/snippets"} })
    end,
    build = "make install_jsregexp",
  },

  {
    'notjedi/nvim-rooter.lua',
    init = function()
      require'nvim-rooter'.setup { }
    end,
  },

  -- Adding this so I can search/replace and preserve letter case
  'tpope/vim-abolish',

  -- Highlighting for tmux
  'tmux-plugins/vim-tmux',

  -- Plug to assist with commenting out blocks of text:
  'tpope/vim-commentary',

  -- Tabular, align equals
  'godlygeek/tabular',

  -- Show markers
  'kshenoy/vim-signature',

  -- Display trailing whitespace
  'ntpeters/vim-better-whitespace',

  -- Auto reload files when changes externally
  'TheZoq2/neovim-auto-autoread',

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = 'canary',
    dependencies = { "github/copilot.vim", 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    init = function()
      require("CopilotChat").setup()
    end,
  },

  -- Show differences with style
  {
    'mhinz/vim-signify',
    int = function()
      vim.api.nvim_set_option('updatetime', 100)
    end,
  },

  {
    'mhinz/vim-grepper',
    init = function()
      local map = require("utils").map
      map('n', '<leader>G', ":Grepper -tool rg -buffer -cword -noprompt<CR>", { silent = true })
      map('n', '<leader>GG', ":Grepper -tool rg -cword -noprompt<CR>", { silent = true })


      -- vim.keymap.set("n", "<leader>G",
      --   function()
      --     local current_word = vim.api.nvim_command_output([[ echo expand('<cword>') ]])
      --     fzf_lua.live_grep({
      --       cmd = grep_cmd,
      --       query = current_word,
      --       cwd = fzf_lua.path.git_root(),
      --     })
      --   end,
      --   { silent = true }
      -- )

    end,
  },

  'vimlab/split-term.vim',

  -- {
  --   'udalov/kotlin-vim',
  --   ft = {'kt'},
  -- },

  -- Colour coding nests
  {
    'luochen1990/rainbow',
    init = function()
      -- 0 if you want to enable it later via :RainbowToggle
      vim.api.nvim_set_var('rainbow_active', 1)
    end,
    cond = false,
  },

  -- {
  --   'echasnovski/mini.nvim',
  --   branch = 'stable',
  --   init = function()
  --     require('mini.sessions').setup()
  --   end,
  -- },

  'mhinz/vim-startify',
  -- {
  --   'szw/vim-maximizer',
  --   init = function()
  --     local map = require("utils").map
  --     map('n', '<leader>z', ':MaximizerToggle<CR>', { silent = true })
  --     map('v', '<leader>z', ':MaximizerToggle<CR>gv', { silent = true })
  --     map('i', '<leader>z', '<C-o>:MaximizerToggle<CR>', { silent = true })

  --     map('n', '<C-w>z', ':MaximizerToggle<CR>', { silent = true })
  --     map('v', '<C-w>z', ':MaximizerToggle<CR>gv', { silent = true })
  --     map('i', '<C-w>z', '<C-o>:MaximizerToggle<CR>', { silent = true })
  --   end,
  -- },

  -- Gaze deeply into unknown regions using the power of the moon.
  'nvim-telescope/telescope.nvim',

  -- Install fzf, the fuzzy searcher (also loads Ultisnips)
  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local map = require("utils").map

      local actions = require "fzf-lua.actions"
      require("fzf-lua").setup({
        actions = {
          files = {
            ["default"]     = actions.file_edit_or_qf,
            ["ctrl-x"]      = actions.file_split,
            ["ctrl-v"]      = actions.file_vsplit,
            ["ctrl-t"]      = actions.file_tabedit,
            ["alt-q"]       = actions.file_sel_to_qf, -- dunno what this does
            ["alt-l"]       = actions.file_sel_to_ll, -- dunno what this does
            ["ctrl-l"]      = require'fzf-lua.actions'.arg_add, -- dunno what this does
          },
          buffers = {
            ["default"]     = actions.buf_edit,
            ["ctrl-x"]      = actions.buf_split,
            ["ctrl-v"]      = actions.buf_vsplit,
            ["ctrl-t"]      = actions.buf_tabedit,
          }
        },
        buffers = {
          actions = {
            ["ctrl-x"] = actions.buf_split,
            ["ctrl-d"] = actions.buf_del,
          }
        },
        tabs = {
          actions = {
            ["ctrl-x"] = actions.buf_split,
            ["ctrl-d"] = actions.buf_del,
          }
        }
      })

      -- Set up keyboard shortbuts for fzf, the fuzzy finder
      -- This one searches all the files in the current git repo:
      map('n', '<c-k>', '<cmd>lua require("fzf-lua").git_files()<CR>', { silent = true })
      map('n', '<leader>h', '<cmd>lua require("fzf-lua").oldfiles()<CR>', { silent = true })
      map('n', '<leader>t', '<cmd>lua require("fzf-lua").tabs()<CR>', { silent = true })
      map('n', '<leader><Tab>', '<cmd>lua require("fzf-lua").buffers()<CR>', { silent = true })

      -- Unmap center/<CR> from launching fzf which appears to be mapped by default.
      -- unmap <CR>

      -- map('n', '<leader>g', '<cmd>lua require("fzf-lua").grep_project()<CR>', { silent = true })
      map('n', '<leader>g', '<cmd>lua require("fzf-lua").live_grep()<CR>', { silent = true })

      vim.keymap.set("n", "gsiw",
        function()
          local fzf_lua = require("fzf-lua")
          local current_word = vim.api.nvim_command_output([[ echo expand('<cword>') ]])
          fzf_lua.live_grep({
            cmd = grep_cmd,
            query = current_word,
            cwd = fzf_lua.path.git_root(),
          })
        end,
        { silent = true }
      )

      map('n', '<leader>l', '<cmd>lua require("fzf-lua").lines()<CR>', { silent = true })
      map('n', '<leader>w', '<cmd>lua require("fzf-lua").Windows()<CR>', { silent = true })

   end,
  },

  -- Better quickfix window
  {
    'kevinhwang91/nvim-bqf', ft = 'qf',
    dependencies = { 'dyng/ctrlsf.vim' }
  },
  -- optional, highly recommended
  {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'},


  -- Plugin to make it easy to delete a buffer and close the file:
  'mhinz/vim-sayonara',

  -- Plugin for working with surroundings of words
  'tpope/vim-surround',

  'azabiong/vim-highlighter',


  -- syntax highlighting for *.hal, *.bp, and *.rc files.
  -- 'https://github.ford.com/MRUSS100/aosp-vim-syntax.git'
  'rubberduck203/aosp-vim',

  {
    'kheaactua/vim-fzf-repo',
     init = function()
      local map = require("utils").map
      map('n', '<leader>k', ':GRepoFiles<CR>', { silent = true })
     end,
     cond = false -- GRepoFiles calls fzf instead of fzf-lua, this needs to be fixed
  },

  -- Vim sugar for the UNIX shell commands that need it the most. Features include:
  -- :Remove: Delete a buffer and the file on disk simultaneously.
  -- :Unlink: Like :Remove, but keeps the now empty buffer.
  -- :Move:   Rename a buffer and the file on disk simultaneously.
  -- :Rename: Like :Move, but relative to the current file's containing directory.
  -- :Chmod:  Change the permissions of the current file.
  -- :Mkdir:  Create a directory, defaulting to the parent of the current file.
  -- :Find:   Run find and load the results into the quickfix list.
  -- :Locate: Run locate and load the results into the quickfix list.
  -- :Wall:   Write every open window. Handy for kicking off tools like guard.
  -- :SudoWrite: Write a privileged file with sudo.
  -- :SudoEdit:  Edit a privileged file with sudo.
  'tpope/vim-eunuch',

  -- Colourschemes
  'joshdick/onedark.nvim',
  'altercation/vim-colors-solarized',
  'kristijanhusak/vim-hybrid-material',
  'atelierbram/vim-colors_duotones',
  'atelierbram/vim-colors_atelier-schemes',
  'arcticicestudio/nord-vim',
  'drewtempelmeyer/palenight.vim',
  'morhetz/gruvbox',
  'mhartington/oceanic-next',
  {'dracula/vim', as = 'dracula'},

  {
    'kheaactua/vim-managecolor',
    init = function()
      dotfiles_dir=vim.api.nvim_get_var('dotfiles')
      vim.api.nvim_set_var('colo_search_path', dotfiles_dir .. '/bundles/dein')
      vim.api.nvim_set_var('colo_cache_file',  dotfiles_dir .. '/colos.json')
    end,
  },

  {
    'ayu-theme/ayu-vim',
     init = function()
      vim.api.nvim_set_var('ayucolor', 'mirage')
    end,
  },

  -- A bunch more...
  {
    'gmist/vim-palette',
  },

}
