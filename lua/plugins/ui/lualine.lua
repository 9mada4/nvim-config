return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local refresh_group = vim.api.nvim_create_augroup("LualineReposcopeRefresh", { clear = true })

    local function is_reposcope()
      return vim.api.nvim_buf_get_name(0):match("^reposcope://") ~= nil
    end

    local function reposcope_hint()
      return "Reposcope  <CR>: search  <C-c>: clone  <C-v>: README  <Esc>: close"
    end

    local function not_reposcope()
      return not is_reposcope()
    end

    require("lualine").setup({
      options = {
        globalstatus = true,
      },
      sections = {
        lualine_a = {
          { "mode", cond = not_reposcope },
        },
        lualine_b = {
          { "branch", cond = not_reposcope },
          { "diff", cond = not_reposcope },
          { "diagnostics", cond = not_reposcope },
        },
        lualine_c = {
          { reposcope_hint, cond = is_reposcope },
          { "filename", cond = not_reposcope },
        },
        lualine_x = {
          { "encoding", cond = not_reposcope },
          { "fileformat", cond = not_reposcope },
          { "filetype", cond = not_reposcope },
        },
        lualine_y = {
          { "progress", cond = not_reposcope },
        },
        lualine_z = {
          { "location", cond = not_reposcope },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          { reposcope_hint, cond = is_reposcope },
          { "filename", cond = not_reposcope },
        },
        lualine_x = {
          { "location", cond = not_reposcope },
        },
        lualine_y = {},
        lualine_z = {},
      },
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave", "WinEnter", "WinLeave" }, {
      group = refresh_group,
      pattern = "reposcope://*",
      callback = function()
        require("lualine").refresh()
      end,
    })
  end,
}
