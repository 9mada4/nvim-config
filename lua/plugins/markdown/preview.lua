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
      if vim.env.COLORTERM == nil or vim.env.COLORTERM == "" then
        vim.env.COLORTERM = "truecolor"
      end

      require("glow").setup({
        glow_path = vim.fn.stdpath("config") .. "/tools/glow-color-preview",
        style = vim.fn.stdpath("config") .. "/styles/glow-tokyonight-headings.json",
        pager = false,
      })
    end,
  },
}
