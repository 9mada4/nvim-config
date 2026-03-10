return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- diagnostics の表示設定
      vim.diagnostic.config({
        virtual_text = true,   -- 行末にエラー内容を表示
        signs = true,          -- 左端にマークを表示
        underline = true,      -- エラー箇所に下線
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
        },
      })

      -- LSP servers
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("marksman")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ts_ls")
    end,
  },
}
