return {
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    keys = {
      { "<leader>cv", "<cmd>CsvViewToggle<CR>", desc = "CSV: Toggle table view" },
    },
    opts = {
      view = {
        display_mode = "border",
      },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<CR>", mode = { "n", "v" } },
      },
    },
  },
}
