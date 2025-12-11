require "launch"

-- Load cmp as a plugin specification
spec "cmp.lua"
spec "colorscheme.lua"

return {
  {
    'tpope/vim-fugitive',
    dependencies = {
       -- rhubarb is suppose to to help fugitive with GitHub, though gh has
       -- consumed a lot of what rhubarb does
      "tpope/vim-rhubarb"
    },
    init = function()
      vim.opt.diffopt:append('vertical')
    end,
  },

  -- Navigating the quickfix window better.  Recommended by fugitive
  'tpope/vim-unimpaired',

  -- This should improve Git Fugitive and Git Gutter
  'tmux-plugins/vim-tmux-focus-events',


  {
    'notjedi/nvim-rooter.lua',
    init = function()
      require('nvim-rooter').setup {
        update_cwd = true,
        update_focused_file = {
          enable = true,
          update_cwd = true
        },
        cd_scope = "window",
      }
    end,
  },

  -- Adding this so I can search/replace and preserve letter case
  'tpope/vim-abolish',

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
    branch = 'main',
    dependencies = {
      "github/copilot.vim",
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'MeanderingProgrammer/render-markdown.nvim',
    },
    init = function()
      -- Configure CopilotChat with minimal settings to avoid conflicts
      local chat_config = {
        prompts = {
          Explain = {
            prompt = "Explain how this code works.",
          },
          FixCode = {
            prompt = "Fix the bugs in this code.",
          },
          Optimize = {
            prompt = "Optimize this code for better performance.",
          },
        },
        mappings = {
          close = {
            normal = "q",
          },
          reset = {
            normal = "<C-l>",
          },
          submit_prompt = {
            normal = "<CR>",
            insert = "<C-CR>",
          },
          accept_diff = {
            normal = "<C-y>",
          },
          complete = {
            insert = '<Tab>',
          },
        },
      }

      -- Initialize the plugin
      local chat = require("CopilotChat")
      chat.setup(chat_config)

      local map = require("utils").map
      map('n', '<leader>c', ":CopilotChatToggle<CR>", { silent = true })

      -- Register copilot-chat filetype
      require('render-markdown').setup({
        file_types = { 'markdown', 'copilot-chat' },
      })

      -- Adjust chat display settings
      require('CopilotChat').setup({
        highlight_headers = false,
        separator = '---',
        error_header = '> [!ERROR] Error',
      })
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
      map('n', '<leader>G', ":Grepper -tool rg<CR>", { silent = true })

      -- Run Grepper on the current selected work
      map('n', '<leader>GG', ":Grepper -tool rg -cword -noprompt<CR>", { silent = true })

      -- map('v', '<leader>GG', ":Grepper -tool rg -noprompt<CR>", { silent = true })
      -- Run grepper in the current buffer
      map('n', '<leader>GGG', ":Grepper -tool rg -buffer -cword -noprompt<CR>", { silent = true })
    end,
  },

  'vimlab/split-term.vim',

  -- Colour coding nests
  {
    'luochen1990/rainbow',
    init = function()
      -- 0 if you want to enable it later via :RainbowToggle
      vim.api.nvim_set_var('rainbow_active', 1)
    end,
    cond = false,
  },

  'mhinz/vim-startify',

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
        },
        -- See https://github.com/ibhagwan/fzf-lua/wiki#can-i-use-ripgreps---globiglob-option-with-live_grep
        grep = {
          rg_glob = true
        }
      })

      -- Set up keyboard shortbuts for fzf, the fuzzy finder
      -- This one searches all the files in the current git repo:
      map('n', '<c-k>', '<cmd>lua require("fzf-lua").git_files()<CR>', { silent = true })
      map('n', '<leader>h', '<cmd>lua require("fzf-lua").oldfiles()<CR>', { silent = true })
      -- map('n', '<leader>t', '<cmd>lua require("fzf-lua").tabs()<CR>', { silent = true })
      map('n', '<leader>t', '<cmd>lua require("fzf-lua").buffers()<CR>', { silent = true })

      -- Unmap center/<CR> from launching fzf which appears to be mapped by default.
      -- unmap <CR>

      -- map('n', '<leader>g', '<cmd>lua require("fzf-lua").grep_project()<CR>', { silent = true, debug = true })
      map('n', '<leader>g', '<cmd>lua require("fzf-lua").live_grep()<CR>', { silent = true })

      vim.keymap.set("n", "gsiw",
        function()
          local fzf_lua = require("fzf-lua")
          local current_word = vim.api.nvim_command_output([[ echo expand('<cword>') ]])
          fzf_lua.live_grep({
            cmd = grep_cmd,
            query = current_word,
          })
        end,
        { silent = true }
      )

      map('n', '<leader>l', '<cmd>lua require("fzf-lua").lines()<CR>', { silent = true })

   end,
  },

  -- Better quickfix window
  {
    'kevinhwang91/nvim-bqf', ft = 'qf',
    dependencies = { 'dyng/ctrlsf.vim' }
  },

  -- Configurations for neovim's language client
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "nvimtools/none-ls.nvim",
      "mhartington/formatter.nvim",
    },
    config = function()
      require("mason").setup({
        -- log_level = vim.log.levels.DEBUG
      })
      require("mason-lspconfig").setup()

      -- Setup none-ls for linting if available
      local ok, null_ls = pcall(require, "none-ls")
      if ok then
        null_ls.setup({
        debug = false,
        sources = {
          -- Add null-ls sources for linting based on your needs
          null_ls.builtins.diagnostics.eslint,
          null_ls.builtins.diagnostics.pylint,
          null_ls.builtins.diagnostics.shellcheck,
          null_ls.builtins.code_actions.gitsigns,
          null_ls.builtins.diagnostics.markdownlint,
          null_ls.builtins.diagnostics.yamllint,
          -- Formatting
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.clang_format,
        },
      })
      end

      -- Install servers automatically
      local ensure_installed = {
        "clangd",          -- C/C++
        "yamlls",          -- YAML
        "bashls",          -- Bash
        "cmake",           -- CMake
        "dockerls",        -- Docker
        "gopls",           -- Go
        "jsonls",          -- JSON
        "marksman",        -- Markdown
        "pyright",         -- Python
        "lua_ls",          -- Lua
      }

      -- Load mason-lspconfig with error handling
      local has_mlc, mlc = pcall(require, "mason-lspconfig")
      if has_mlc then
        mlc.setup {
          ensure_installed = ensure_installed,
          -- automatic_installation = true,
          handlers = {
            function (server_name)
              local has_cmp_lsp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
              local capabilities = has_cmp_lsp and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
              require("lspconfig")[server_name].setup {
                capabilities = capabilities
              }
            end,
          }
        }
      end

      -- Configure diagnostics to show inline
      vim.diagnostic.config({
        virtual_text = true,  -- Enable inline diagnostics
        signs = true,         -- Show signs in the sign column
        underline = true,     -- Underline text with issues
        update_in_insert = false,
        severity_sort = true,
      })

      -- Global mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
      vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', '<leader>rD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', '<leader>rd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<leader>rk', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>ty', vim.lsp.buf.type_definition, opts)
          vim.keymap.set('n', '<leader>rw', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>rf', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>fu', function()
            vim.lsp.buf.format { async = true }
          end, opts)
          vim.keymap.set('v', '<leader>fu', function()
            vim.lsp.buf.format { async = true }
          end, opts)
        end,
      })

      -- Setup formatter
      formatter = require('formatter')
      formatter.setup({
        -- Enable or disable logging
        logging = true,

        -- Set the log level
        log_level = vim.log.levels.WARN,

        filetype = {
          ["yaml"] = {
            require("formatter.filetypes.yaml").yamlfmt
          },
          ["*"] = {
            require("formatter.filetypes.any").remove_trailing_whitespace
          }
        }
      })

    end
  },


  -- {
  --   "williamboman/mason.nvim",
  --   config = function ()
  --     require("mason").setup()
  --   end,
  -- },

  -- {
  --   "williamboman/mason-lspconfig.nvim",
  --   after = { "mason.nvim", "nvim-lspconfig" },
  --   dependencies = {
  --     -- "williamboman/mason.nvim",
  --     -- "williamboman/mason-lspconfig.nvim",
  --     -- -- "mason-org/mason.nvim",
  --     -- -- "mason-org/mason-lspconfig.nvim",
  --     -- "nvimtools/none-ls.nvim",
  --     "mhartington/formatter.nvim",
  --   },
  --   config = function()
  --     require('mason').setup({})
  --     require('mason-lspconfig').setup({
  --       ensure_installed = {
  --         "clangd",          -- C/C++
  --         "yamlls",          -- YAML
  --         "bashls",          -- Bash
  --         "cmake",           -- CMake
  --         "dockerls",        -- Docker
  --         "gopls",           -- Go
  --         "jsonls",          -- JSON
  --         "marksman",        -- Markdown
  --         "pyright",         -- Python
  --         "lua_ls",          -- Lua
  --       }
  --     })
  --     -- require('lspconfig').lua_ls.setup({})
  --     -- require('lspconfig').pyright.setup({})
  --     -- require('lspconfig').ts_ls.setup({})
  --   end
  -- },

  -- -- Configurations for neovim's language client
  -- {
  --   'neovim/nvim-lspconfig',
  --   dependencies = {
  --     "williamboman/mason.nvim",
  --     "williamboman/mason-lspconfig.nvim",
  --     -- "mason-org/mason.nvim",
  --     -- "mason-org/mason-lspconfig.nvim",
  --     "nvimtools/none-ls.nvim",
  --     "mhartington/formatter.nvim",
  --   },
  --   config = function()
  --     require("mason").setup()
  --     -- require("mason-lspconfig").setup()

  --     -- Setup none-ls for linting if available
  --     local ok, null_ls = pcall(require, "none-ls")
  --     if ok then
  --       null_ls.setup({
  --       debug = false,
  --       sources = {
  --         -- Add null-ls sources for linting based on your needs
  --         null_ls.builtins.diagnostics.eslint,
  --         null_ls.builtins.diagnostics.pylint,
  --         null_ls.builtins.diagnostics.shellcheck,
  --         null_ls.builtins.code_actions.gitsigns,
  --         null_ls.builtins.diagnostics.markdownlint,
  --         null_ls.builtins.diagnostics.yamllint,
  --         -- Formatting
  --         null_ls.builtins.formatting.prettier,
  --         null_ls.builtins.formatting.black,
  --         null_ls.builtins.formatting.clang_format,
  --       },
  --     })
  --     end

  --     -- require("mason").setup()

  --     -- Install servers automatically
  --     local ensure_installed = {
  --       -- "clangd",          -- C/C++
  --       -- "yamlls",          -- YAML
  --       -- "bashls",          -- Bash
  --       -- "cmake",           -- CMake
  --       -- "dockerls",        -- Docker
  --       -- "gopls",           -- Go
  --       -- "jsonls",          -- JSON
  --       -- "marksman",        -- Markdown
  --       -- "pyright",         -- Python
  --       "lua_ls",          -- Lua
  --     }

  --     -- Load mason-lspconfig with error handling
  --     local has_mlc, mlc = pcall(require, "mason-lspconfig")
  --     if has_mlc then
  --       -- print("mason-lspconfig loaded successfully")
  --       -- print(vim.inspect(mlc))
  --       mlc.setup {
  --         ensure_installed = ensure_installed,
  --         -- handlers = {
  --         --   function (server_name)
  --         --     local has_cmp_lsp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
  --         --     local capabilities = has_cmp_lsp and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
  --         --     require("lspconfig")[server_name].setup {
  --         --       capabilities = capabilities
  --         --     }
  --         --   end,
  --         -- }
  --       }

  --       -- -- Setup LSP handlers
  --       -- mlc.setup_handlers {
  --       -- -- The first entry (without a key) will be the default handler
  --       -- -- and will be called for each installed server that doesn't have
  --       -- -- a dedicated handler.
  --       -- function (server_name) -- default handler (optional)
  --       --   local has_cmp_lsp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
  --       --   local capabilities = has_cmp_lsp and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

  --       --   require("lspconfig")[server_name].setup {
  --       --     capabilities = capabilities
  --       --   }
  --       -- end,
  --       -- }
  --     end

  --     -- Configure diagnostics to show inline
  --     vim.diagnostic.config({
  --       virtual_text = true,  -- Enable inline diagnostics
  --       signs = true,         -- Show signs in the sign column
  --       underline = true,     -- Underline text with issues
  --       update_in_insert = false,
  --       severity_sort = true,
  --     })

  --     -- Global mappings.
  --     -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  --     vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
  --     vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
  --     vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
  --     vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

  --     -- Use LspAttach autocommand to only map the following keys
  --     -- after the language server attaches to the current buffer
  --     vim.api.nvim_create_autocmd('LspAttach', {
  --       group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  --       callback = function(ev)
  --         -- Enable completion triggered by <c-x><c-o>
  --         vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

  --         -- Buffer local mappings.
  --         -- See `:help vim.lsp.*` for documentation on any of the below functions
  --         local opts = { buffer = ev.buf }
  --         vim.keymap.set('n', '<leader>rD', vim.lsp.buf.declaration, opts)
  --         vim.keymap.set('n', '<leader>rd', vim.lsp.buf.definition, opts)
  --         vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  --         vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  --         vim.keymap.set('n', '<leader>rk', vim.lsp.buf.signature_help, opts)
  --         vim.keymap.set('n', '<leaderty', vim.lsp.buf.type_definition, opts)
  --         vim.keymap.set('n', '<leader>rw', vim.lsp.buf.rename, opts)
  --         vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
  --         vim.keymap.set('n', '<leader>rf', vim.lsp.buf.references, opts)
  --         vim.keymap.set('n', '<leader>fu', function()
  --           vim.lsp.buf.format { async = true }
  --         end, opts)
  --         vim.keymap.set('v', '<leader>fu', function()
  --           vim.lsp.buf.format { async = true }
  --         end, opts)
  --       end,
  --     })

  --     -- Setup formatter
  --     formatter = require('formatter')
  --     formatter.setup({
  --       -- Enable or disable logging
  --       logging = true,

  --       -- Set the log level
  --       log_level = vim.log.levels.WARN,

  --       filetype = {
  --         ["yaml"] = {
  --           require("formatter.filetypes.yaml").yamlfmt
  --         },
  --         ["*"] = {
  --           require("formatter.filetypes.any").remove_trailing_whitespace
  --         }
  --       }
  --     })

  --   end
  -- },

  -- Plugin to make it easy to delete a buffer and close the file:
  'mhinz/vim-sayonara',

  -- Plugin for working with surroundings of words
  'tpope/vim-surround',

  'azabiong/vim-highlighter',

  -- syntax highlighting for *.hal, *.bp, and *.rc files.
  -- 'https://github.ford.com/MRUSS100/aosp-vim-syntax.git'
  -- 'rubberduck203/aosp-vim',

  {
    'kheaactua/vim-fzf-repo',
     init = function()
      local map = require("utils").map
      map('n', '<leader>k', ':GRepoFiles<CR>', { silent = true })
     end,
     cond = false -- GRepoFiles calls fzf instead of fzf-lua, this needs to be fixed
  },

  {
    'kheaactua/aosp-vim-syntax',
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
  'joshdick/onedark.vim',
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
    -- dir = "/home/matt/workspace/vim-managecolor", -- For local development
    config = function()
      require("managecolor").setup({
        collections = {
          whitelist = {
            "palenight",
            "duotone-darkearth",
            "duotone-darkpool",
            "hybrid_material",
            "hybrid_reverse",
            "3dglasses",
            "ChocolateLiquor",
            "MountainDew",
            "PapayaWhip",
            -- "Revolution",
            -- "Tomorrow-Night-Eighties",
            -- "abbott",
            "anotherdark",
            -- "argonaut",
            "atom",
            "autumn",
            "ayu",
            "base16-ateliersulphurpool",
            -- "birds-of-paradise",
            "blackboard",
            "blackdust",
            "blacklight",
            "blue",
            "bluechia",
            "bocau",
            "breeze",
            "busybee",
            "bvemu",
            -- "camo",
            "candycode",
            "chance-of-storm",
            "clarity",
            "clue",
            "cobalt",
            "codeschool",
            "colorsbox-steighties",
            "colorzone",
            "cool",
            "corporation",
            "darkBlue",
            "darkdot",
            "darkslategray",
            "darkspectrum",
            "darktango",
            "desertedocean",
            "desertedoceanburnt",
            "deveiate",
            "distinguished",
            "doorhinge",
            "dusk",
            -- "eclipse",
            "ecostation",
            "ego",
            -- "elrodeo",
            "flatland",
            -- "flatlandia",
            "flattened_dark",
            "forneus",
            "fruidle",
            "fruity",
            "gemcolors",
            "golden",
            "gor",
            -- "gotham",
            "greenvision",
            -- "gryffin",
            "guardian",
            "guepardo",
            "h80",
            -- "herokudoc-gvim",
            "herokudoc",
            -- "hotpot",
            "hydrangea",
            "inkpot",
            "kalisi",
            "kib_darktango",
            "lingodirector",
            "madeofcode",
            "maroloccio",
            "materialbox",
            "materialtheme",
            "mint",
            "monokai-chris",
            "mopkai",
            "mud",
            -- "nefertiti",
            -- "neodark",
            -- "neonwave",
            -- "neverland-darker",
            "newsprint",
            "night",
            "nightflight2",
            "nord",
            "northland",
            "onedark",
            "oxeded",
            "paintbox",
            "phd",
            "playroom",
            "predawn",
            "pspad",
            "radicalgoodspeed",
            "rdark",
            "sand",
            "scite",
            -- "scooby",
            "selenitic",
            "sexy-railscasts",
            "sf",
            "shadesofamber",
            "silent",
            "smp",
            "softbluev2",
            "sonofobsidian",
            "strawimodo",
            "summerfruit",
            "summerfruit256",
            "swamplight",
            "taqua",
            "turbo",
            "twilight256",
            "two2tango",
            "umber-green",
            "underwater-mod",
            "underwater",
          },
          diff = {
            "autumn",
            "bvemu",
            "clue",
            "darkspectrum",
            "distinguished",
            "nefertiti"
          },
        },
      })
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
