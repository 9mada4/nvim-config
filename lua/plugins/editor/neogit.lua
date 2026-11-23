return {
  "NeogitOrg/neogit",
  cmd = "Neogit",
  keys = {
    { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    disable_hint = true,
    builders = {
      NeogitCommitPopup = function(builder)
        builder:new_action_group("Generate")
          :action("g", "Generate (Rule)", function()
            require("config.neogit").commit("rule")
          end)
          :action("G", "Generate (Rule + LLM)", function()
            require("config.neogit").commit("full")
          end)
      end,
    },
  },
  config = function(_, opts)
    require("neogit").setup(opts)
    require("config.neogit").setup_hints()
  end,
}
