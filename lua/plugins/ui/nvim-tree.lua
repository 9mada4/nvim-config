return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local function apply_help_key_highlights()
      local ok, help = pcall(require, "nvim-tree.help")
      if not ok or not help.bufnr or not vim.api.nvim_buf_is_valid(help.bufnr) then
        return
      end

      local bufnr = help.bufnr
      local ns = vim.api.nvim_create_namespace("MyNvimTreeHelp")
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local key_hl_map = {
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
      end, {
        buffer = bufnr,
        desc = "nvim-tree: Help",
        noremap = true,
        silent = true,
        nowait = true,
      })
    end

    vim.api.nvim_set_hl(0, "NvimTreeHelpDanger", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "NvimTreeHelpRename", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "NvimTreeHelpOpen", { link = "DiagnosticInfo" })

    require("nvim-tree").setup({
      on_attach = on_attach,
    })
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
  end,
}
