return {
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = "127.0.0.1"
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_preview_options = {
        sync_scroll_type = "middle",
        disable_filename = 1,
      }
    end,
  },
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
