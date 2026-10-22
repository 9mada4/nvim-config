return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        signature = {
          auto_open = {
            enabled = false,
          },
        },
      },
      cmdline = {
        enabled = true,
      },
      popupmenu = {
        enabled = true,
      },
      presets = {
        command_palette = true,
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
}
