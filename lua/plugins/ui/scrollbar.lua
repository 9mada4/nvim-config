return {
  {
    "petertriho/nvim-scrollbar",
    branch = "refactor/v2", -- Remove after v2 lands on main.
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local colors = require("tokyonight.colors").setup()
      local providers = require("scrollbar.providers")

      local function cursorword_marks(bufnr)
        if bufnr ~= vim.api.nvim_get_current_buf() or vim.bo[bufnr].buftype ~= "" or vim.fn.mode() ~= "n" then
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
      end

      providers.register({
        name = "cursorword",
        refresh_owner = { buffer = "manager" },
        setup = function(context)
          vim.api.nvim_create_autocmd({ "CursorMoved", "WinEnter", "InsertEnter", "ModeChanged" }, {
            group = context.create_augroup("cursorword"),
            callback = function()
              local bufnr = vim.api.nvim_get_current_buf()
              context.set_marks(bufnr, cursorword_marks(bufnr))
            end,
          })
        end,
        refresh = cursorword_marks,
      })

      require("scrollbar").setup({
        set_highlights = true,
        exclude = {
          buftypes = { "terminal" },
          filetypes = {
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
        },
        marks = {
          Cursor = {
            text = "•",
            highlight = { fg = colors.fg_gutter },
          },
          Search = {
            highlight = { fg = colors.orange },
          },
          Error = {
            highlight = { fg = colors.error },
          },
          Warn = {
            highlight = { fg = colors.warning },
          },
          Info = {
            highlight = { fg = colors.info },
          },
          Hint = {
            highlight = { fg = colors.hint },
          },
          Misc = {
            text = { "•", "•" },
            highlight = { fg = "#5a678f" },
          },
          GitAdd = {
            highlight = { fg = colors.green },
          },
          GitChange = {
            highlight = { fg = colors.yellow },
          },
          GitDelete = {
            highlight = { fg = colors.red },
          },
        },
        providers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
          search = false,
          marks = false,
          ale = false,
        },
        scrollbar = {
          show = true,
          visibility = "active",
          unit = "screenline",
          max_lines = false,
          hide_if_all_visible = false,
          hide_on_cursor = false,
          mouse = false,
          throttle_ms = 80,
          layout = {
            columns = { { "thumb", "marks" } },
          },
          thumb = {
            text = " ",
            blend = 45,
            highlight = { bg = colors.bg_highlight },
            hide_if_all_visible = true,
          },
        },
      })
    end,
  },
}
