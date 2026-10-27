return {
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = function(plugin)
      local yarn = vim.fn.executable("yarn") == 1
          and { "yarn", "install", "--frozen-lockfile" }
        or { "npm", "exec", "--yes", "--package=yarn@1.22.22", "--", "yarn", "install", "--frozen-lockfile" }
      local result = vim.system(yarn, {
        cwd = plugin.dir .. "/app",
        text = true,
      }):wait()
      if result.code ~= 0 then
        error("Failed to install markdown-preview.nvim: " .. (result.stderr or "unknown error"))
      end

      local mermaid_asset = vim.fn.stdpath("data") .. "/markdown-preview/mermaid.min.js"
      local update = vim.system({
        "node",
        vim.fn.stdpath("config") .. "/scripts/install-markdown-preview-mermaid.cjs",
        mermaid_asset,
      }, { text = true }):wait()
      if update.code ~= 0 then
        error("Failed to install Mermaid 11 for markdown-preview.nvim: " .. (update.stderr or "unknown error"))
      end
    end,
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = "127.0.0.1"
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_preview_options = {
        sync_scroll_type = "middle",
        disable_filename = 1,
      }
    end,
    config = function()
      -- Override the plugin's refresh events while keeping its preview lifecycle.
      vim.cmd.source(vim.fn.stdpath("config") .. "/autoload/mkdp/autocmd.vim")
      require("config.markdown_preview").setup_commands()
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
