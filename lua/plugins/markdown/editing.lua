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
          vim.opt_local.shiftwidth = 2
          vim.opt_local.tabstop = 2
          vim.opt_local.softtabstop = 2
          vim.opt_local.numberwidth = 2
          vim.opt_local.foldcolumn = "0"
          vim.opt_local.signcolumn = "number"

          -- Work around first-open stale markdown preview until cursor moves.
          vim.defer_fn(function()
            if not vim.api.nvim_buf_is_valid(args.buf) then
              return
            end
            local ok, markview = pcall(require, "markview")
            if ok and markview and type(markview.render) == "function" then
              markview.render(args.buf)
            end
          end, 40)

          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("i", "<CR>", "<CR><Cmd>AutolistNewBullet<CR>", opts)
          vim.keymap.set("n", "o", "o<Cmd>AutolistNewBullet<CR>", opts)
          vim.keymap.set("n", "O", "O<Cmd>AutolistNewBulletBefore<CR>", opts)
        end,
      })
    end,
  },
}
