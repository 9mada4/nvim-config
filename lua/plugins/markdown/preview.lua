return {
  {
    "npxbr/glow.nvim",
    ft = { "markdown" },
    cmd = { "Glow" },
    config = function()
      require("glow").setup({})
    end,
  },
}
