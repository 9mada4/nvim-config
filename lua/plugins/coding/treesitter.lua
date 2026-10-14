return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})
    -- main ブランチではパーサーの導入とハイライトの開始を別々に行う。
    treesitter.install({ "lua", "bash", "json", "markdown", "markdown_inline", "html", "latex" })

    -- HTML 本文の Markdown 解析は .md バッファだけに適用する。
    vim.treesitter.query.add_predicate("markdown-buffer?", function(_, _, source)
      return type(source) == "number" and vim.bo[source].filetype == "markdown"
    end, { force = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
      pattern = { "lua", "sh", "bash", "json", "markdown", "html" },
      callback = function(event)
        if pcall(vim.treesitter.start, event.buf) then
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
