return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local has_html_lsp = vim.fn.executable("node") == 1
        and vim.fn.executable("vscode-html-language-server") == 1
      local has_superhtml = vim.fn.executable("superhtml") == 1

      -- Allow HTML completion inside Markdown buffers.
      vim.lsp.config("html", {
        filetypes = { "html", "markdown" },
      })
      vim.lsp.config("superhtml", {
        filetypes = { "superhtml" },
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
      if has_html_lsp then
        vim.lsp.enable("html")
      elseif has_superhtml then
        vim.lsp.enable("superhtml")
      end
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("marksman")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ts_ls")
    end,
  },
}
