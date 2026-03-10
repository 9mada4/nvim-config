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
    { "<leader>mp", "<cmd>PasteImage<CR>", desc = "Paste image from clipboard" },
  },
}
