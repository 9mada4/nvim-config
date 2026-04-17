local function ensure_lazygit_color_env()
  if vim.fn.has("mac") ~= 1 then
    return
  end

  if vim.env.NO_COLOR ~= nil then
    vim.env.NO_COLOR = nil
  end
  if vim.env.TERM == nil or vim.env.TERM == "" or vim.env.TERM == "dumb" then
    vim.env.TERM = "xterm-256color"
  end
  if vim.env.COLORTERM == nil or vim.env.COLORTERM == "" then
    vim.env.COLORTERM = "truecolor"
  end
end

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
    config = function()
      ensure_lazygit_color_env()
    end,
  },
}
