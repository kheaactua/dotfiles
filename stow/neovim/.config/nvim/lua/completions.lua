vim.o.completeopt = "menuone,noselect"

local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local cmp_status, cmp = pcall(require, 'cmp')
if cmp_status then
  luasnip = require("luasnip")
  cmp.setup({
    snippet = {
      expand = function(args)
        -- For `vsnip` user.
        vim.fn["vsnip#anonymous"](args.body)
      end,
    },
    mapping = {
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      -- ['<Tab>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
      -- ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<Down>"] = cmp.mapping(function(fallback)
        if nil == luasnip then
          return
        end
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),


      ["<Up>"] = cmp.mapping(function(fallback)
        if nil == luasnip then
          return
        end
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),

      ["<c-j>"] = cmp.mapping(function(fallback)
        if nil == luasnip then
          return
        end
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { "i", "s" }),

    },
    sources = {
      -- For vsnip user.
      { name = 'vsnip' },

      { name = 'nvim_lsp' },

      { name = 'buffer' },
    }
  })

  if 1 == vim.fn.executable("clangd") then
    require('lspconfig').clangd.setup {
      capabilities = require('cmp_nvim_lsp').default_capabilities()
    }
  end


  if 1 == vim.fn.executable("cmake-language-server") then
    require('lspconfig').cmake.setup {
      capabilities = require('cmp_nvim_lsp').default_capabilities()
    }
  end

  -- require('lspconfig').kotlin.setup {
  --   capabilities = require('cmp_nvim_lsp').default_capabilities()
  -- }

  if 1 == vim.fn.executable("bash-language-server") then
    require('lspconfig').bashls.setup {
      capabilities = require('cmp_nvim_lsp').default_capabilities()
    }
  end

  -- require('lspconfig').gopls.setup {
  --   capabilities = require('cmp_nvim_lsp').default_capabilities()
  -- }
end
