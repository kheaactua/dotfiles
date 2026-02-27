-- Configure colorscheme and cmp via plugins/lazy.nvim
require("config.lazy")

-- Set up clipboard to work optimally in all situations:
-- - Local with system clipboard tools: use xclip/wl-clipboard (fastest, most reliable)
-- - Remote SSH or tmux: OSC 52 works through terminal escape sequences
-- - Auto-detects and uses the best available method
if os.getenv("SSH_CONNECTION") or os.getenv("TMUX") then
  -- Use OSC 52 for remote/tmux sessions
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
else
  -- Use system clipboard tools for local sessions (faster, more reliable)
  vim.opt.clipboard = 'unnamedplus'
end
