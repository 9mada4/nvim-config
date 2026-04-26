return {
  {
    "petertriho/nvim-scrollbar",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local colors = require("tokyonight.colors").setup()
      local handlers = require("scrollbar.handlers")

      handlers.register("cursorword", function(bufnr)
        if vim.bo[bufnr].buftype ~= "" or vim.fn.mode() ~= "n" then
          return {}
        end

        if vim.api.nvim_buf_line_count(bufnr) > 10000 then
          return {}
        end

        local word = vim.fn.expand("<cword>")
        if word == nil or word == "" or #word < 2 then
          return {}
        end

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local pattern = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
        local marks = {}

        for index, line in ipairs(lines) do
          if vim.fn.match(line, pattern) >= 0 then
            marks[#marks + 1] = {
              line = index - 1,
              text = "•",
              type = "Misc",
            }
          end
        end

        return marks
      end)

      require("scrollbar").setup({
        show = true,
        show_in_active_only = true,
        set_highlights = true,
        folds = 1000,
        max_lines = false,
        hide_if_all_visible = false,
        throttle_ms = 80,
        handle = {
          text = " ",
          blend = 45,
          color = colors.bg_highlight,
          highlight = "CursorColumn",
          hide_if_all_visible = true,
        },
        marks = {
          Cursor = {
            text = "•",
            color = colors.fg_gutter,
          },
          Search = {
            color = colors.orange,
          },
          Error = {
            color = colors.error,
          },
          Warn = {
            color = colors.warning,
          },
          Info = {
            color = colors.info,
          },
          Hint = {
            color = colors.hint,
          },
          Misc = {
            text = { "•", "•" },
            color = "#5a678f",
          },
          GitAdd = {
            color = colors.green,
          },
          GitChange = {
            color = colors.yellow,
          },
          GitDelete = {
            color = colors.red,
          },
        },
        excluded_buftypes = {
          "terminal",
        },
        excluded_filetypes = {
          "NvimTree",
          "TelescopePrompt",
          "cmp_docs",
          "cmp_menu",
          "dropbar_menu",
          "dropbar_menu_fzf",
          "lazy",
          "mason",
          "noice",
          "prompt",
          "reposcope",
        },
        autocmd = {
          render = {
            "BufWinEnter",
            "CursorMoved",
            "DiagnosticChanged",
            "TabEnter",
            "TextChanged",
            "TextChangedI",
            "VimResized",
            "WinEnter",
            "WinScrolled",
          },
          clear = {
            "BufWinLeave",
            "TabLeave",
            "WinLeave",
          },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
          handle = true,
          search = false,
          ale = false,
        },
      })
    end,
  },
}
