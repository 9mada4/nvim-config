return {
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = function(plugin)
      local result = vim.system({ "yarn", "install", "--frozen-lockfile" }, {
        cwd = plugin.dir .. "/app",
        text = true,
      }):wait()
      if result.code ~= 0 then
        error("Failed to install markdown-preview.nvim: " .. (result.stderr or "unknown error"))
      end
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
