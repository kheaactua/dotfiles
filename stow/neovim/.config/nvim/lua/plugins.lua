local fn = vim.fn
-- TODO At least use 'home' and 'username' or something here
vim.api.nvim_set_var('dotfiles', '/home/matt/dotfiles')

local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost /home/**/plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Have packer use a popup window
packer.init({
    display = {
      open_fn = function()
        return require('packer.util').float({ border = 'single' })
      end
    }
  }
)

-- Install your plugins here
return packer.startup(function(use)
  use 'wbthomason/packer.nvim' -- Have packer manage itself
  use "nvim-lua/popup.nvim" -- An implementation of the Popup API from vim in Neovim
  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins

  -- Conditionally install with something like:
  -- https://github.com/wbthomason/packer.nvim/discussions/196#discussioncomment-345837

  -- Simple plugins can be specified as strings
  -- use 'rstacruz/vim-closer'

  -- Lazy loading:
  -- Load on specific commands
  -- use {'tpope/vim-dispatch', opt = true, cmd = {'Dispatch', 'Make', 'Focus', 'Start'}}

  -- Load on an autocommand event
  use {'andymass/vim-matchup', event = 'VimEnter'}

 use {
    'tpope/vim-fugitive',
    config = function()
      vim.opt.diffopt:append('vertical')
    end,
  }

  -- Used for navigating the quickfix window better.  Recommended by fugitive
  use 'tpope/vim-unimpaired'

  -- This should improve Git Fugitive and Git Gutter
  use 'tmux-plugins/vim-tmux-focus-events'

  use {
    "L3MON4D3/LuaSnip",
    tag = "v1.*",
    config = function()
      -- vim.keymap.set({ "i", "s" }, "<C-i>", function() require'luasnip'.jump(1)  end, { desc = "LuaSnip forward jump"  })
      -- vim.keymap.set({ "i", "s" }, "<M-i>", function() require'luasnip'.jump(-1) end, { desc = "LuaSnip backward jump" })

      dotfiles_dir=vim.api.nvim_get_var('dotfiles')
      -- require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_snipmate").lazy_load({ paths = { dotfiles_dir .. "/snippets"} })
    end,
  }

  use {
    'notjedi/nvim-rooter.lua',
    config = function()
      require'nvim-rooter'.setup {
      }
    end,
  }

  -- Adding this so I can search/replace and preserve letter case
  use 'tpope/vim-abolish'

  -- Highlighting for tmux
  use 'tmux-plugins/vim-tmux'

  -- Plug to assist with commenting out blocks of text:
  use 'tpope/vim-commentary'

  -- Tabular, align equals
  use 'godlygeek/tabular'

  -- Show markers
  use 'kshenoy/vim-signature'

  -- Display trailing whitespace
  use 'ntpeters/vim-better-whitespace'

  use 'TheZoq2/neovim-auto-autoread'

  use {
    'Hdima/python-syntax',
    ft = {'py', 'fsb'},
  }

  use {
    "jose-elias-alvarez/null-ls.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      local nl = require("null-ls")

      nl.setup({
        sources={
          -- python
          nl.builtins.formatting.black.with({
            extra_args = { "--line-length=120" },
            filetypes = {"py", "fsb"},
          }),
          nl.builtins.diagnostics.pylint.with({
            extra_args = { "--max-line-length=120" }
          }),

          -- nl.builtins.diagnostics.cmake_lint.with({
          --   extra_args = { "--line-width=120" }
          -- }),
          nl.builtins.formatting.isort,
          -- nl.builtins.formatting.clang_format,
        },
      })

      local map = require("utils").map
      map('n', '<leader>fu', '<cmd>lua vim.lsp.buf.format({ timeout_ms = 2000 })<CR>', { silent = true })
      map('n', '<leader>fU', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', { silent = true })
    end
  }

  use {
    'mhinz/vim-signify',
    config = function()
      vim.api.nvim_set_option('updatetime', 100)
    end,
  }

  use 'vimlab/split-term.vim'

  use {
    'udalov/kotlin-vim',
    ft = {'kt'},
  }

  -- Colour coding nests
  use {
    'luochen1990/rainbow',
    config = function()
      -- 0 if you want to enable it later via :RainbowToggle
      vim.api.nvim_set_var('rainbow_active', 1)
    end,
    cond = false,
  }

  use 'tpope/vim-obsession'
  use 'mhinz/vim-startify'
  use {
    'szw/vim-maximizer',
    config = function()
      local map = require("utils").map
      map('n', '<leader>z', ':MaximizerToggle<CR>', { silent = true })
      map('v', '<leader>z', ':MaximizerToggle<CR>gv', { silent = true })
      map('i', '<leader>z', '<C-o>:MaximizerToggle<CR>', { silent = true })

      map('n', '<C-w>z', ':MaximizerToggle<CR>', { silent = true })
      map('v', '<C-w>z', ':MaximizerToggle<CR>gv', { silent = true })
      map('i', '<C-w>z', '<C-o>:MaximizerToggle<CR>', { silent = true })
    end,
  }

  use 'nvim-telescope/telescope.nvim'

  -- Install fzf, the fuzzy searcher (also loads Ultisnips)
  use {
    'ibhagwan/fzf-lua',
    requires = {
      { 'nvim-tree/nvim-web-devicons' },
      {
        'junegunn/fzf',
        run = './install --all',
      }
    },
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
            query = current_word,
            cwd = fzf_lua.path.git_root(),
          })
        end,
        { silent = true }
      )

      map('n', '<leader>l', '<cmd>lua require("fzf-lua").lines()<CR>', { silent = true })
      map('n', '<leader>w', '<cmd>lua require("fzf-lua").Windows()<CR>', { silent = true })

   end,

  }

  -- Configurations for neovim's language client
  use {
    'neovim/nvim-lspconfig',
    requires = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      vim.api.nvim_set_var('clang_path', '/usr')

      local map = require("utils").map
      map('n', '<leader>rd', '<cmd>lua vim.lsp.buf.declaration()<CR>', { silent = true })
      map('n', '<leader>rj', '<cmd>lua vim.lsp.buf.definition()<CR>', { silent = true })
      map('n', '<leader>ty', '<cmd>lua vim.lsp.buf.hover()<CR>', { silent = true })
      map('n', '<leader>rk', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { silent = true })
      map('n', '<leader>rf', '<cmd>lua vim.lsp.buf.references()<CR>', { silent = true })
      map('n', '<leader>ds', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', { silent = true })
      map('n', '<leader>rw', '<cmd>lua vim.lsp.buf.rename()<CR>', { silent = true })
      map('n', '<leader>c ', '<cmd>lua vim.lsp.buf.code_action()<CR>', { silent = true })
      map('n', '<leader>m ', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', { silent = true })
      map('n', '<leader>el', '<cmd>lua print(vim.lsp.get_log_path())<CR>', { silent = true })

      -- Various mappings to open the corresponding header/source file in a new split
      map('n', '<leader>of', '<cmd>ClangdSwitchSourceHeader<CR>', { silent = true })
      map('n', '<leader>oh', '<cmd>vsp<CR><cmd>ClangdSwitchSourceHeader<CR>', { silent = true })
      map('n', '<leader>oj', '<cmd>below sp<CR><cmd>ClangdSwitchSourceHeader<CR>', { silent = true })
      map('n', '<leader>ok', '<cmd>sp<CR><cmd>ClangdSwitchSourceHeader<CR>', { silent = true })
      map('n', '<leader>ol', '<cmd>below vsp<CR><cmd>ClangdSwitchSourceHeader<CR>', { silent = true })

      map('n', '[z', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', { silent = true })
      map('n', ']z', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', { silent = true })

      require("_lsp").setup()
    end
  }
  use { 'ojroques/nvim-lspfuzzy', required = { 'fzf' } }

  use 'mhinz/vim-sayonara' -- Plugin to make it easy to delete a buffer and close the file:

  -- Autocompletion plugin
  use {
    'hrsh7th/nvim-cmp',
    config = function()
      -- TODO Maybe I can remove these commented lines
      -- vim.api.nvim_set_option('completeopt', 'menuone,noselect')

      -- local map = require("utils").map
      -- map('i', '<C-Space>', 'compe#complete()', { silent = true, expr=1 })
      -- map('i', '<CR>', 'compe#confirm("<CR>")', { silent = true, expr=1 })
      -- map('i', '<C-e>', 'compe#close("<C-e>")', { silent = true, expr=1 })
      -- map('i', '<C-f>', 'compe#scroll({ "delta": +4 })', { silent = true, expr=1 })
      -- map('i', '<C-d>', 'compe#scroll({ "delta": -4 })', { silent = true, expr=1 })
     end
  }
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'

  -- Plugin for working with surroundings of words
  use 'tpope/vim-surround'

  -- A plugin for asynchronous linting while you type
  use {
    'w0rp/ale',
    ft = {'sh', 'zsh', 'bash', 'c', 'cpp', 'cmake', 'html', 'markdown', 'racket', 'vim', 'tex'},
    cmd = 'ALEEnable',
    config = function()
      vim.cmd[[ALEEnable]]

      vim.api.nvim_set_var('ale_linters', {
        cpp = {'clangtidy'},
        c   = {'clangtidy'},
      })

      vim.api.nvim_set_var('ale_fixers', {
        cpp = {'clang-format'},
        ['*'] = {'remove_trailing_lines', 'trim_whitespace'}
      })

      local map = require("utils").map
      -- Set up mapping to move between errors
      map('i', '[w', '<Plug>(ale_previous_wrap)', { silent = true })
      map('i', ']w', '<Plug>(ale_next_wrap)',     { silent = true} )

      vim.cmd([[ autocmd FileType c,cpp,h,hpp nnoremap <buffer><leader>fu :ALEFix<CR> ]])

    end,
  }

  use {
    'itchyny/lightline.vim',
    config = function()
      vim.api.nvim_set_var('lightline', {
        colorscheme = 'one',
        component_function = {
          filename = 'LightlineFilename',
        }
      })
      vim.api.nvim_set_var('unite_force_overwrite_statusline', 0)
      vim.api.nvim_set_var('vimfiler_force_overwrite_statusline', 0)
      vim.api.nvim_set_var('vimshell_force_overwrite_statusline', 0)
      vim.api.nvim_set_var('lightline.separator', { left = '', right = '' })
      vim.api.nvim_set_var('lightline.subseparator', { left = '', right = '' })
    end,
    cond = false
  }
  -- use 'maximbaz/lightline-ale'
  -- use 'kosayoda/nvim-lightbulb'

  use {
    'PProvost/vim-ps1',
    ft = {'ps1'}
  }

  -- syntax highlighting for *.hal, *.bp, and *.rc files.
  -- use 'https://github.ford.com/MRUSS100/aosp-vim-syntax.git'
  use 'rubberduck203/aosp-vim'

  use {
    'kheaactua/vim-fzf-repo',
     config = function()
      local map = require("utils").map
      map('n', '<leader>k', ':GRepoFiles<CR>', { silent = true })
     end,
     cond = false -- GRepoFiles calls fzf instead of fzf-lua, this needs to be fixed
  }

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
  use 'tpope/vim-eunuch'

  -- Colourschemes
  use 'navarasu/onedark.nvim'
  use 'altercation/vim-colors-solarized'
  use 'kristijanhusak/vim-hybrid-material'
  use 'atelierbram/vim-colors_duotones'
  use 'atelierbram/vim-colors_atelier-schemes'
  use 'rakr/vim-one'
  use 'arcticicestudio/nord-vim'
  use 'drewtempelmeyer/palenight.vim'
  use 'morhetz/gruvbox'
  use 'mhartington/oceanic-next'
  use {'dracula/vim', as = 'dracula'}

  use {
    'ayu-theme/ayu-vim',
     config = function()
      vim.api.nvim_set_var('ayucolor', 'mirage')
    end,
  }

  -- A bunch more...
  use {
    'gmist/vim-palette',
  }

  use {
    'kheaactua/vim-managecolor',
    config = function()
      dotfiles_dir=vim.api.nvim_get_var('dotfiles')
      vim.api.nvim_set_var('colo_search_path', dotfiles_dir .. '/bundles/dein')
      vim.api.nvim_set_var('colo_cache_file',  dotfiles_dir .. '/colos.json')
    end,
  }

  -- /Colourschemes


  -- use 'majutsushi/tagbar'
  -- use 'hoschi/yode-nvim'
  -- use 'mtth/scratch.vim'
  -- use 'editorconfig/editorconfig-vim'

--   -- Plugins can have dependencies on other plugins
--   use {
--     'haorenW1025/completion-nvim',
--     opt = true,
--     requires = {{'hrsh7th/vim-vsnip', opt = true}, {'hrsh7th/vim-vsnip-integ', opt = true}}
--   }

  -- Local plugins can be included
  -- use '~/projects/personal/hover.nvim'

  -- -- Plugins can have post-install/update hooks
  -- use {'iamcco/markdown-preview.nvim', run = 'cd app && yarn install', cmd = 'MarkdownPreview'}

  -- Better highlighting
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = "all",
        highlight = { enable = true },
        indent = { enable = true }
      }
    end
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require('packer').sync()
  end
end)
