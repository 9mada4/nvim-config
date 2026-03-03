return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",

  opts = {
    ensure_installed = { "lua", "bash", "json", "markdown" },

    highlight = {
      enable = true,
    },

    indent = {
      enable = true,
    },
  },
}
