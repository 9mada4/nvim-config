return {
  {
    "npxbr/glow.nvim",
    enabled = vim.fn.executable("glow") == 1,
    ft = { "markdown" },
    cmd = { "Glow" },
    config = function()
      require("glow").setup({})
    end,
  },
}
