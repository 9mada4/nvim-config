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
        builder:new_action_group()
          :action("g", "Gen-Rule", function()
            require("config.neogit").commit("rule")
          end)
          :action("G", "Gen-Rule+LLM", function()
            require("config.neogit").commit("full")
          end)
        -- Groups render as columns without wrapping, so a separate column is
        -- cut off in narrow windows. Move g/G under Create (the first group).
        local groups = builder.state.actions
        local generate = table.remove(groups)
        vim.list_extend(groups[1], generate, 2)
      end,
    },
  },
  config = function(_, opts)
    require("neogit").setup(opts)
    require("config.neogit").setup_hints()
    require("config.neogit_popup").setup()
  end,
}
