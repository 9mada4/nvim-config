return {
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown" },
    config = function()
      require("autolist").setup()

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
            vim.opt_local.wrap = false
            local opts = { buffer = args.buf, silent = true }
            vim.keymap.set("i", "<CR>", "<CR><Cmd>AutolistNewBullet<CR>", opts)
            vim.keymap.set("n", "o", "o<Cmd>AutolistNewBullet<CR>", opts)
            vim.keymap.set("n", "O", "O<Cmd>AutolistNewBulletBefore<CR>", opts)
        end,
      })
    end,
  },
}
