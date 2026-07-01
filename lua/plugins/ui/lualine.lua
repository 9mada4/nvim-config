return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local refresh_group = vim.api.nvim_create_augroup("LualineReposcopeRefresh", { clear = true })

    local function is_reposcope()
      return vim.api.nvim_buf_get_name(0):match("^reposcope://") ~= nil
    end

    local function is_codex_terminal()
      local bufnr = vim.api.nvim_get_current_buf()
      if vim.bo[bufnr].buftype ~= "terminal" then
        return false
      end

      if vim.b[bufnr].codex_terminal == true then
        return true
      end

      return vim.api.nvim_buf_get_name(bufnr):lower():find("codex", 1, true) ~= nil
    end

    local function reposcope_hint()
      return "Reposcope  <CR>: search  <C-c>: clone  <C-v>: README  <Esc>: close"
    end

    local function codex_hint()
      return "Codex  /model: model  /new: new chat  Spc+ci: image"
    end

    local function special_hint()
      if is_reposcope() then
        return reposcope_hint()
      end
      if is_codex_terminal() then
        return codex_hint()
      end
      return ""
    end

    local function is_special()
      return is_reposcope() or is_codex_terminal()
    end

    local function not_special()
      return not is_special()
    end

    require("lualine").setup({
      options = {
        globalstatus = true,
      },
      sections = {
        lualine_a = {
          { "mode", cond = not_special },
        },
        lualine_b = {
          { "branch", cond = not_special },
          { "diff", cond = not_special },
          { "diagnostics", cond = not_special },
        },
        lualine_c = {
          { special_hint, cond = is_special },
          { "filename", cond = not_special },
        },
        lualine_x = {
          { "encoding", cond = not_special },
          { "fileformat", cond = not_special },
          { "filetype", cond = not_special },
        },
        lualine_y = {
          { "progress", cond = not_special },
        },
        lualine_z = {
          { "location", cond = not_special },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          { special_hint, cond = is_special },
          { "filename", cond = not_special },
        },
        lualine_x = {
          { "location", cond = not_special },
        },
        lualine_y = {},
        lualine_z = {},
      },
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave", "TermOpen", "WinEnter", "WinLeave" }, {
      group = refresh_group,
      callback = function()
        require("lualine").refresh()
      end,
    })
  end,
}
