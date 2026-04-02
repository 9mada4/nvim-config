return {
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
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
  {
    "arminveres/md-pdf.nvim",
    branch = "main",
    lazy = true,
    keys = {
      {
        "<leader>,",
        function()
          require("md-pdf").convert_md_to_pdf()
        end,
        desc = "Markdown preview",
      },
    },
    opts = {
      pdf_engine = "lualatex",
      fonts = {
        main_font = "Hiragino Sans",
        sans_font = "Hiragino Sans",
        mono_font = "Hiragino Sans",
      },
    },
    config = function(_, opts)
      local ok_utils, utils = pcall(require, "md-pdf.utils")
      if ok_utils and utils.log and utils.log.warn then
        local original_warn = utils.log.warn
        utils.log.warn = function(msg)
          if type(msg) == "string"
            and msg:find("When specifying custom fonts, you may encounter utf-8 error", 1, true)
            and opts.pdf_engine ~= "pdflatex"
          then
            return
          end
          original_warn(msg)
        end
      end
      require("md-pdf").setup(opts)
    end,
  },
}
