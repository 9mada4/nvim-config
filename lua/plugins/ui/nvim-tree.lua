return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local hint = {
      bufnr = nil,
      winid = nil,
    }
    local hint_ns = vim.api.nvim_create_namespace("NvimTreeHelpHint")
    local hint_group = vim.api.nvim_create_augroup("NvimTreeHelpHint", { clear = true })

    local function close_help_hint()
      if hint.winid and vim.api.nvim_win_is_valid(hint.winid) then
        pcall(vim.api.nvim_win_close, hint.winid, true)
      end

      hint.winid = nil

      if hint.bufnr and vim.api.nvim_buf_is_valid(hint.bufnr) then
        pcall(vim.api.nvim_buf_delete, hint.bufnr, { force = true })
      end

      hint.bufnr = nil
    end

    local function is_nvim_tree_win(winid)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        return false
      end

      local bufnr = vim.api.nvim_win_get_buf(winid)
      return vim.bo[bufnr].filetype == "NvimTree"
    end

    local function has_bottom_space(winid)
      local height = vim.api.nvim_win_get_height(winid)
      if height < 3 then
        return false
      end

      return vim.api.nvim_win_call(winid, function()
        local top = vim.fn.line("w0")
        local bottom = vim.fn.line("w$")
        local last = vim.fn.line("$")

        return bottom >= last and (bottom - top + 1) < height
      end)
    end

    local function set_hint_text(bufnr, text)
      vim.bo[bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { text })
      vim.bo[bufnr].modifiable = false
      vim.api.nvim_buf_clear_namespace(bufnr, hint_ns, 0, -1)
      vim.api.nvim_buf_add_highlight(bufnr, hint_ns, "NvimTreeHelpHintText", 0, 0, -1)
    end

    local function ensure_hint_buf(text)
      if not hint.bufnr or not vim.api.nvim_buf_is_valid(hint.bufnr) then
        hint.bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[hint.bufnr].bufhidden = "wipe"
        vim.bo[hint.bufnr].buftype = "nofile"
        vim.bo[hint.bufnr].filetype = "nvim-tree-help-hint"
        vim.bo[hint.bufnr].swapfile = false
      end

      set_hint_text(hint.bufnr, text)
      return hint.bufnr
    end

    local function update_help_hint()
      local tree_win = vim.api.nvim_get_current_win()
      if not is_nvim_tree_win(tree_win) or not has_bottom_space(tree_win) then
        close_help_hint()
        return
      end

      local text = "g? shortcuts"
      local tree_width = vim.api.nvim_win_get_width(tree_win)
      if tree_width < vim.fn.strdisplaywidth(text) + 2 then
        text = "g?"
      end

      local bufnr = ensure_hint_buf(text)
      local config = {
        relative = "win",
        win = tree_win,
        row = vim.api.nvim_win_get_height(tree_win) - 1,
        col = 1,
        width = math.min(vim.fn.strdisplaywidth(text), math.max(tree_width - 1, 1)),
        height = 1,
        style = "minimal",
        border = "none",
        focusable = false,
        zindex = 40,
      }

      if hint.winid and vim.api.nvim_win_is_valid(hint.winid) then
        local ok = pcall(vim.api.nvim_win_set_config, hint.winid, config)
        if ok then
          return
        end

        hint.winid = nil
      end

      hint.winid = vim.api.nvim_open_win(bufnr, false, config)
      vim.wo[hint.winid].winhl = "NormalFloat:NvimTreeNormal"
      vim.wo[hint.winid].wrap = false
      vim.wo[hint.winid].cursorline = false
      vim.wo[hint.winid].number = false
      vim.wo[hint.winid].relativenumber = false
    end

    local function schedule_help_hint_update()
      vim.schedule(update_help_hint)
    end

    local function apply_help_key_highlights()
      local ok, help = pcall(require, "nvim-tree.help")
      if not ok or not help.bufnr or not vim.api.nvim_buf_is_valid(help.bufnr) then
        return
      end

      local bufnr = help.bufnr
      local ns = vim.api.nvim_create_namespace("MyNvimTreeHelp")
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local key_hl_map = {
        ["<C-]>"] = "NvimTreeHelpOpen",
        a = "NvimTreeHelpCreate",
        d = "NvimTreeHelpDanger",
        D = "NvimTreeHelpDanger",
        e = "NvimTreeHelpRename",
        r = "NvimTreeHelpRename",
        s = "NvimTreeHelpOpen",
        u = "NvimTreeHelpRename",
      }

      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

      for row, line in ipairs(lines) do
        local lhs = line:match("^%s+(%S+)")
        local higroup = lhs and key_hl_map[lhs]

        if higroup then
          local col = line:find(lhs, 1, true)
          if col then
            local start_col = col - 1
            local end_col = start_col + #lhs

            if vim.fn.has("nvim-0.11") == 1 and vim.hl and vim.hl.range then
              vim.hl.range(bufnr, ns, higroup, { row - 1, start_col }, { row - 1, end_col }, {})
            else
              vim.api.nvim_buf_add_highlight(bufnr, ns, higroup, row - 1, start_col, end_col)
            end
          end
        end
      end
    end

    local function on_attach(bufnr)
      local api = require("nvim-tree.api")

      api.map.on_attach.default(bufnr)

      vim.keymap.set("n", "g?", function()
        api.tree.toggle_help()
        vim.schedule(apply_help_key_highlights)
        schedule_help_hint_update()
      end, {
        buffer = bufnr,
        desc = "nvim-tree: Help",
        noremap = true,
        silent = true,
        nowait = true,
      })

      schedule_help_hint_update()
    end

    vim.api.nvim_set_hl(0, "NvimTreeHelpDanger", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "NvimTreeHelpCreate", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "NvimTreeHelpRename", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "NvimTreeHelpOpen", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "NvimTreeHelpHintText", { link = "Comment" })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CursorMoved", "WinScrolled", "VimResized" }, {
      group = hint_group,
      callback = schedule_help_hint_update,
    })

    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
      group = hint_group,
      callback = schedule_help_hint_update,
    })

    require("nvim-tree").setup({
      on_attach = on_attach,
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = {
          enable = true,
        },
      },
      filters = {
        git_ignored = false,
      },
    })
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
  end,
}
