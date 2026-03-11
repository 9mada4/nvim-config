return {
  {
    "pwntester/octo.nvim",
    enabled = vim.fn.executable("gh") == 1,
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      picker = "telescope",
      enable_builtin = true,
    },
    keys = {
      { "<leader>gr", "<cmd>Octo repo list<CR>", desc = "GitHub Repos" },
      { "<leader>gp", "<cmd>Octo pr list<CR>", desc = "GitHub PRs" },
      { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "GitHub Issues" },
      { "<leader>gn", "<cmd>Octo notification list<CR>", desc = "GitHub Notifications" },
    },
  },
}
