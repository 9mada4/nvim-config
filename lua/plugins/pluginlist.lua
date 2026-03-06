return {
  require("plugins.ui.nvim-tree"),
  require("plugins.ui.lualine"),
  require("plugins.ui.tokyonight"),
  require("plugins.ui.which-key"),

  require("plugins.editor.telescope"),
  require("plugins.editor.gitsigns"),
  require("plugins.editor.lazygit"),
  require("plugins.editor.autopairs"),
  require("plugins.editor.comment"),

  require("plugins.coding.treesitter"),
  require("plugins.coding.mason"),
  require("plugins.coding.lsp"),
  require("plugins.coding.cmp"),
}
