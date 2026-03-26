return {
  "StefanBartl/reposcope.nvim",
  name = "reposcope",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("reposcope.init").setup({})

    vim.keymap.set("n", "<leader>rs", "<cmd>ReposcopeStart<CR>", {
      desc = "Reposcope: search repositories",
    })
  end,
}
