return {
  "StefanBartl/reposcope.nvim",
  name = "reposcope",
  event = "VeryLazy",
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    -- Use reposcope's setup entry point only. Requiring and overriding internal
    -- modules makes this configuration break whenever the plugin reorganizes them.
    require("reposcope.init").setup({})

    vim.keymap.set("n", "<leader>rs", "<cmd>ReposcopeStart<CR>", {
      desc = "Reposcope: search repositories",
    })
  end,
}
