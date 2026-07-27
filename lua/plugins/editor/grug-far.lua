return {
  "MagicDuck/grug-far.nvim",
  opts = {},
  keys = {
    {
      "<leader>sR",
      function()
        require("grug-far").open()
      end,
      desc = "Search and replace in working directory",
    },
  },
}
