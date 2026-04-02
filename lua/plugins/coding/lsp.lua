return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local has_npm = vim.fn.executable("npm") == 1

      -- Allow HTML completion inside Markdown buffers.
      vim.lsp.config("html", {
        filetypes = { "html", "markdown" },
      })
      vim.lsp.config("superhtml", {
        filetypes = { "superhtml", "html", "markdown" },
      })

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
      if has_npm then
        vim.lsp.enable("html")
      else
        vim.lsp.enable("superhtml")
      end
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("marksman")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ts_ls")
    end,
  },
}
