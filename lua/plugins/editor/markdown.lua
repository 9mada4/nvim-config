return {
  -- Markdown の構文認識
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "markdown",
        "markdown_inline",
      })
    end,
  },

  -- Markdown を見やすく表示
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
          enabled = true,
          sign = false,
          width = "block",
          disable_background = true,
          left_pad = 0,
          right_pad = 0,
          min_width = 0,
          border = "none",
          language_name = true,
          language_icon = true,
          language_border = "",
          inline = false,
        },
        heading = {
          enabled = false,
        },
      })

      vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#40383E" })
    end,
  },

  -- ブラウザで Markdown プレビュー
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = {
      "MarkdownPreview",
      "MarkdownPreviewStop",
      "MarkdownPreviewToggle",
    },
    build = "cd app && yarn install --frozen-lockfile",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },

  -- 箇条書きを自動継続
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown" },
    config = function()
      require("autolist").setup()

      vim.keymap.set("i", "<CR>", "<CR><Cmd>AutolistNewBullet<CR>", { buffer = true })
      vim.keymap.set("n", "o", "o<Cmd>AutolistNewBullet<CR>", { buffer = true })
      vim.keymap.set("n", "O", "O<Cmd>AutolistNewBulletBefore<CR>", { buffer = true })
    end,
  },
}
