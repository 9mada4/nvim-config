return {
  {
    "ishiooon/codex.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    cmd = {
      "Codex",
      "CodexFocus",
      "CodexSend",
      "CodexTreeAdd",
    },
    keys = {
      { "<leader>cc", "<cmd>Codex<CR>", desc = "Codex: Toggle" },
      { "<leader>cf", "<cmd>CodexFocus<CR>", desc = "Codex: Focus" },
      { "<leader>cs", "<cmd>CodexSend<CR>", mode = "v", desc = "Codex: Send selection" },
    },
    opts = function()
      local cmd = vim.fn.exepath("codex")
      if cmd == "" and vim.fn.filereadable("/Applications/Codex.app/Contents/Resources/codex") == 1 then
        cmd = "/Applications/Codex.app/Contents/Resources/codex"
      end
      if cmd == "" then
        cmd = nil
      end

      return {
        terminal_cmd = cmd,
        terminal = {
          provider = "snacks",
          snacks_win_opts = {
            position = "bottom",
            height = 0.35,
          },
        },
        status_indicator = {
          enabled = false,
        },
      }
    end,
  },
}
