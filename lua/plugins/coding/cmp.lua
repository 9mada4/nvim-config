return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local tex_commands = require("config.cmp_tex_commands")

      require("config.cmp_html_tag_pairs").register()
      tex_commands.register()
      vim.api.nvim_set_hl(0, "CmpBorderWhite", { fg = "#ffffff", bg = "NONE" })

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:CmpBorderWhite,CursorLine:Visual,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:CmpBorderWhite,CursorLine:Visual,Search:None",
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            else
              cmp.complete()
            end
          end, { "i" }),
          ["<C-p>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
            else
              cmp.complete()
            end
          end, { "i" }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "path" },
        }),
      })

      cmp.setup.filetype("markdown", {
        sources = cmp.config.sources({
          { name = "html_tag_pairs" },
          { name = "path" },
          { name = "nvim_lsp" },
        }),
      })

      cmp.setup.filetype("html", {
        sources = cmp.config.sources({
          { name = "html_tag_pairs" },
          { name = "nvim_lsp" },
          { name = "path" },
        }),
      })

      for _, filetype in ipairs({ "tex", "plaintex", "latex" }) do
        cmp.setup.filetype(filetype, {
          sources = cmp.config.sources({
            { name = "tex_commands", keyword_length = 0 },
            {
              name = "buffer",
              keyword_length = 1,
              entry_filter = function(_, ctx)
                return not tex_commands.is_reference_context(ctx.cursor_before_line)
              end,
            },
            { name = "path" },
            { name = "nvim_lsp" },
          }),
        })
      end

      local tex_pair_group = vim.api.nvim_create_augroup("cmp-tex-pair-completion", { clear = true })
      vim.api.nvim_create_autocmd("CursorMovedI", {
        group = tex_pair_group,
        desc = "Open TeX argument completion after an automatic closing brace",
        callback = function(args)
          local filetype = vim.bo[args.buf].filetype
          if filetype ~= "tex" and filetype ~= "plaintex" and filetype ~= "latex" then
            return
          end

          local line = vim.api.nvim_get_current_line()
          local column = vim.api.nvim_win_get_cursor(0)[2]
          local line_before_cursor = line:sub(1, column)
          local line_after_cursor = line:sub(column + 1)

          if not cmp.visible() and tex_commands.should_complete_after_pair(line_before_cursor, line_after_cursor) then
            cmp.complete({
              config = {
                sources = {
                  { name = "tex_commands", keyword_length = 0 },
                },
              },
            })
          end
        end,
      })
    end,
  },
}
