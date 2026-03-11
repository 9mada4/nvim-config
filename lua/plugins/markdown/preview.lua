return {
  {
    "npxbr/glow.nvim",
    ft = { "markdown" },
    cmd = { "Glow" },
    config = function()
      if vim.env.NO_COLOR ~= nil then
        vim.env.NO_COLOR = nil
      end

      if vim.env.TERM == nil or vim.env.TERM == "" or vim.env.TERM == "dumb" then
        vim.env.TERM = "xterm-256color"
      end

      require("glow").setup({
        style = "dracula",
        pager = true,
      })
    end,
  },
}
