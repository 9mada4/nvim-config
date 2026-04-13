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
    config = true,
  },
}
