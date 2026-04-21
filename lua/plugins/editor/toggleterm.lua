return {
  {
    "akinsho/toggleterm.nvim",
    lazy = false,
    version = "*",
    config = function()
      require("toggleterm").setup({
        direction = "float",
        start_in_insert = true,
        persist_mode = true,
        shade_terminals = false,
        float_opts = {
          border = "rounded",
        },
      })

      local Terminal = require("toggleterm.terminal").Terminal
      local popup_terminal = Terminal:new({
        hidden = true,
        direction = "float",
        float_opts = {
          border = "rounded",
        },
        on_open = function(term)
          vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
            buffer = term.bufnr,
            silent = true,
            desc = "Terminal: normal mode",
          })
          vim.keymap.set("n", "q", function()
            term:close()
          end, {
            buffer = term.bufnr,
            silent = true,
            desc = "Terminal: close popup",
          })
        end,
      })

      vim.keymap.set({ "n", "t" }, "<leader>tt", function()
        popup_terminal:toggle()
      end, { desc = "Terminal: toggle popup" })
    end,
  },
}
