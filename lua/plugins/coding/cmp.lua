return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "path" },
        }),
      })

      cmp.setup.filetype("markdown", {
        sources = cmp.config.sources({
          { name = "path" },
          { name = "nvim_lsp" },
        }),
      })
    end,
  },
}
