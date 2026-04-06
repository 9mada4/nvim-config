local M = {}

local state = {
  buf = nil,
  win = nil,
  chan = nil,
  timer = nil,
}

local function is_valid_buf(buf)
  return type(buf) == "number" and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
  return type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

local function float_config()
  local width = math.max(80, math.floor(vim.o.columns * 0.78))
  width = math.min(width, math.max(80, vim.o.columns - 4))
  local height = math.max(12, math.floor(vim.o.lines * 0.38))
  height = math.min(height, math.max(12, vim.o.lines - 4))
  local row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(1, math.floor((vim.o.columns - width) / 2))

  return {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = true,
    noautocmd = true,
    zindex = 320,
  }
end

local function ensure_term_window()
  if not is_valid_buf(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.buf, "reposcope://clone-terminal")
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].swapfile = false
  end

  if not is_valid_win(state.win) then
    state.win = vim.api.nvim_open_win(state.buf, false, float_config())
  else
    vim.api.nvim_win_set_config(state.win, float_config())
  end

  vim.api.nvim_set_hl(0, "ReposcopeCloneTerm", { bg = "#1b2133", fg = "#c7d2fe" })
  vim.api.nvim_set_hl(0, "ReposcopeCloneTermBorder", { fg = "#7aa2f7", bg = "#1b2133" })
  vim.wo[state.win].winhighlight = "Normal:ReposcopeCloneTerm,FloatBorder:ReposcopeCloneTermBorder"
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].cursorline = false
  vim.wo[state.win].signcolumn = "no"
end

local function schedule_close(timeout)
  stop_timer()
  state.timer = vim.uv.new_timer()
  state.timer:start(timeout, 0, vim.schedule_wrap(function()
    M.close()
  end))
end

function M.close()
  stop_timer()

  if is_valid_win(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end

  state.buf = nil
  state.win = nil
  state.chan = nil
end

function M.run_clone_terminal(args, on_exit)
  if type(args) ~= "table" or #args == 0 then
    return false
  end

  M.close()
  ensure_term_window()

  if is_valid_buf(state.buf) then
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})
    vim.bo[state.buf].modifiable = false
  end

  local chan = nil
  vim.api.nvim_buf_call(state.buf, function()
    chan = vim.fn.termopen(args, {
      on_exit = function(_, code, _)
        vim.schedule(function()
          if type(on_exit) == "function" then
            pcall(on_exit, code)
          end

          if code == 0 then
            schedule_close(1000)
          else
            schedule_close(4000)
          end
        end)
      end,
    })
  end)

  if not chan or chan <= 0 then
    M.close()
    return false
  end

  state.chan = chan
  return true
end

return M
