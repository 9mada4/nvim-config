return {
  {
    "kdheepak/lazygit.nvim",
    enabled = vim.fn.executable("lazygit") == 1,
    cmd = {
      "LazyGit",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
