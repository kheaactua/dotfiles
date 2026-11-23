local M = {
  "hrsh7th/nvim-cmp",
  priority = 50,  -- High priority to load early
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-cmdline" },
    { "saadparwaiz1/cmp_luasnip" },
    { "hrsh7th/cmp-emoji" },
    { "hrsh7th/cmp-nvim-lua" },
    {
      "L3MON4D3/LuaSnip",
      dependencies = { "rafamadriz/friendly-snippets" },
    },
  },
  lazy = false,  -- Load immediately, not just on InsertEnter
}

function M.config()
  vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
  vim.api.nvim_set_hl(0, "CmpItemKindTabnine", { fg = "#CA42F0" })
  vim.api.nvim_set_hl(0, "CmpItemKindCrate", { fg = "#F64D00" })
  vim.api.nvim_set_hl(0, "CmpItemKindEmoji", { fg = "#FDE030" })

  local cmp = require("cmp")
  local luasnip = require("luasnip")

  -- Load snippets
  require("luasnip/loaders/from_vscode").lazy_load()
  require("luasnip").filetype_extend("typescriptreact", { "html" })

  local check_backspace = function()
    local col = vim.fn.col(".") - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
  end

  local has_words_before = function()
    if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
  end

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-k>"] = cmp.mapping.select_prev_item(),
      ["<C-j>"] = cmp.mapping.select_next_item(),
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
        -- Kind icons
        vim_item.kind = string.format("%s", vim_item.kind)

        -- Source
        vim_item.menu = ({
          nvim_lsp = "[LSP]",
          luasnip = "[Snippet]",
          buffer = "[Buffer]",
          path = "[Path]",
          copilot = "[Copilot]",
          emoji = "[Emoji]",
        })[entry.source.name]

        -- Special formatting for Copilot
        if entry.source.name == "copilot" then
          vim_item.kind = " Copilot"
          vim_item.kind_hl_group = "CmpItemKindCopilot"
        end

        return vim_item
      end,
    },
    sources = cmp.config.sources({
      { name = "copilot", group_index = 1 },
      { name = "nvim_lsp", group_index = 1 },
      { name = "luasnip", group_index = 1 },
      { name = "buffer", group_index = 2 },
      { name = "path", group_index = 2 },
      { name = "emoji", group_index = 3 },
      { name = "nvim_lua", group_index = 1, ft = "lua" },
    }),
    confirm_opts = {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    window = {
      completion = {
        border = "rounded",
        winhighlight = "Normal:Pmenu,CursorLine:PmenuSel,FloatBorder:FloatBorder,Search:None",
        scrollbar = false,
      },
      documentation = {
        border = "rounded",
        winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,Search:None",
      },
    },
    experimental = {
      ghost_text = true,
    },
    enabled = function()
      -- Disable completion in comments
      local ok, context = pcall(require, "cmp.config.context")
      -- Keep command mode completion enabled when cursor is in a comment
      if vim.api.nvim_get_mode().mode == "c" then
        return true
      else
        return ok and not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
      end
    end,
  })

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      { name = "cmdline" },
    }),
  })

  -- Set up lspconfig if available
  local has_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  local capabilities = has_cmp_lsp and cmp_lsp.default_capabilities() or nil

  -- Setup for when autopairs is used
  local has_autopairs, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
  if has_autopairs then
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
end

return M
