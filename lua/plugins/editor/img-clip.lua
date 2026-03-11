return {
  "HakonHarnes/img-clip.nvim",
  ft = { "markdown" },
  opts = {
    default = {
      dir_path = "./",
      use_absolute_path = false,
      relative_to_current_file = true,
    },
    filetypes = {
      markdown = {
        template = "![]($FILE_PATH)",
      },
    },
  },
  keys = {
    {
      "<leader>mp",
      function()
        local ok, err = pcall(vim.cmd, "PasteImage")
        if not ok then
          vim.notify("PasteImage failed: " .. tostring(err), vim.log.levels.WARN)
        end
      end,
      desc = "Paste image from clipboard",
    },
  },
}
