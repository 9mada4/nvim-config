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
        anti_conceal = {
          enabled = false,
        },
        win_options = {
          concealcursor = {
            rendered = vim.o.concealcursor,
          },
        },
        code = {
          enabled = false,
        },
        heading = {
          enabled = false,
        },
      })

      vim.api.nvim_set_hl(0, "MarkdownCodeBlockBg", { bg = "#40383E" })
      vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", { link = "MarkdownCodeBlockBg" })
      vim.api.nvim_set_hl(0, "@markup.raw.block", { link = "MarkdownCodeBlockBg" })
    end,
  },
}
