return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local ensure_installed = {
        "lua_ls",
        "marksman",
        "pyright",
        "ts_ls",
      }

      if vim.fn.executable("npm") == 1 then
        table.insert(ensure_installed, "html")
      else
        table.insert(ensure_installed, "superhtml")
      end

      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        automatic_installation = true,
      })
    end,
  },
}
