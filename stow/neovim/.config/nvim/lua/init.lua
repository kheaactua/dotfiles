-- Configure colorscheme and cmp via plugins/lazy.nvim
require("config.lazy")

-- Set up the clipboard to use osc52, which allows copying to the system clipboard
-- This is useful when using neovim inside a docker container or a remote server.
vim.g.clipboard = 'osc52'
