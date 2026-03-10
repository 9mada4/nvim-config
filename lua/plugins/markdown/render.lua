return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, parser in ipairs({ "markdown", "markdown_inline" }) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.nvim",
    },
    config = function()
      require("render-markdown").setup({
        code = {
            width = 'block',
            left_pad = 2,
            right_pad = 4,
        },
        heading = {
            enabled = true,
            sign = false,
            icons = { "󰼏 ", "󰎨 ", "󰼑 ", "󰎲 ", "󰼓 ", "󰎴 " },
            position = 'overlay',
            width = 'block',
            left_margin = 0,
            left_pad = 0,
            right_pad = 4,
            min_width = 0,
            border = false,
            border_virtual = false,
            border_prefix = false,
            -- above = '▄',
            -- below = '▀',
            above = '_',
            below = '‾',
            backgrounds = {
                'RenderMarkdownH1Bg',
                'RenderMarkdownH2Bg',
                'RenderMarkdownH3Bg',
                'RenderMarkdownH4Bg',
                'RenderMarkdownH5Bg',
                'RenderMarkdownH6Bg',
            },
            -- backgrounds = {},
            foregrounds = {
                'RenderMarkdownH1',
                'RenderMarkdownH2',
                'RenderMarkdownH3',
                'RenderMarkdownH4',
                'RenderMarkdownH5',
                'RenderMarkdownH6',
            },
            custom = {},
         },
      })

      -- -- 1. 背景色Aを定義
      -- -- vim.api.nvim_set_hl(0, "MarkdownCodeBlockBg", { fg = "fg", bg = "#40383E" })
      vim.api.nvim_set_hl(0, "MarkdownCodeBlockBg", { link = "@markup.raw.markdown_inline" })
      -- -- 2.1. コードブロック本文に背景色Aを当てる
      vim.api.nvim_set_hl(0, "markdownCodeBlock", { link = "MarkdownCodeBlockBg" })
      -- -- 2.2. コードフェンスの```などにも背景色Aを当てる
      vim.api.nvim_set_hl(0, "markdownCodeDelimiter", { link = "MarkdownCodeBlockBg" })
    end,
  },
}
