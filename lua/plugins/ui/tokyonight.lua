return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd("colorscheme tokyonight")

    vim.api.nvim_set_hl(0, "MsgArea", { fg = "#ff9e64", bold = true })
  end,
}
