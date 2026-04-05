local M = {}

local state = {
  search = nil,
  clone = nil,
  buf = nil,
  win = nil,
}

local function current_message()
  return state.clone or state.search or "Ready"
end

local function is_valid_buf(buf)
  return type(buf) == "number" and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
  return type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function render()
  if not is_valid_buf(state.buf) then
    return
  end

  local ui_config = require("reposcope.ui.config")
  local lines = { " " .. current_message() }
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  if is_valid_win(state.win) then
    vim.api.nvim_win_set_config(state.win, {
      relative = "editor",
      row = ui_config.row + 3,
      col = ui_config.col + 1,
      width = math.max(20, ui_config.width - 2),
      height = 1,
    })
  end
end

function M.open()
  vim.schedule(function()
    local ui_config = require("reposcope.ui.config")

    if not is_valid_buf(state.buf) then
      state.buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(state.buf, "reposcope://status")
      vim.bo[state.buf].buftype = "nofile"
      vim.bo[state.buf].bufhidden = "wipe"
      vim.bo[state.buf].swapfile = false
    end

    if not is_valid_win(state.win) then
      state.win = vim.api.nvim_open_win(state.buf, false, {
        relative = "editor",
        row = ui_config.row + 3,
        col = ui_config.col + 1,
        width = math.max(20, ui_config.width - 2),
        height = 1,
        style = "minimal",
        border = "none",
        focusable = false,
        noautocmd = true,
        zindex = 60,
      })
    end

    vim.api.nvim_set_hl(0, "ReposcopeStatus", {
      bg = "#25273a",
      fg = "#aeb7d9",
      bold = true,
    })
    vim.wo[state.win].winhighlight = "Normal:ReposcopeStatus"
    render()
  end)
end

function M.close()
  vim.schedule(function()
    if is_valid_win(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    state.buf = nil
  end)
end

local function set_field(field, value)
  state[field] = value
  vim.schedule(render)
end

function M.set_search(value)
  set_field("search", value)
end

function M.clear_search()
  set_field("search", nil)
end

function M.set_clone(value)
  set_field("clone", value)
end

function M.clear_clone()
  set_field("clone", nil)
end

function M.component()
  return ""
end

return M
