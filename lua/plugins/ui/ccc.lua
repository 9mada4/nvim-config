return {
  {
    "uga-rosa/ccc.nvim",
    event = "BufReadPre",
    config = function()
      local ccc = require("ccc")

      ccc.setup({
        highlighter = {
          auto_enable = true,
          lsp = true,
        },
      })

      vim.keymap.set("n", "<leader>cp", "<Cmd>CccPick<CR>", { desc = "Color picker" })
    end,
  },
}
