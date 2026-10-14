local M = {}

local states = {}

local function close_preview(win, source_win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if vim.api.nvim_win_is_valid(source_win) then
    vim.api.nvim_set_current_win(source_win)
  end
end

function M.preview(buf)
  local state = states[buf]
  if not state or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if state.status == "running" then
    vim.notify("LLM補足文を生成中です", vim.log.levels.INFO)
    return
  end
  if state.status ~= "ready" then
    vim.notify("LLM補足文を生成できませんでした", vim.log.levels.WARN)
    return
  end

  local source_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(source_win) ~= buf then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(source_win)
  local lines = state.lines
  local width = math.max(1, math.min(96, vim.o.columns - 4))
  local available_height = math.max(1, vim.o.lines - 6)
  local display_rows = 0
  for _, line in ipairs(lines) do
    display_rows = display_rows + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / width))
  end
  local height = math.min(available_height, math.max(1, display_rows))

  local preview = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(preview, 0, -1, false, lines)
  vim.bo[preview].modifiable = false
  vim.bo[preview].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(preview, true, {
    relative = "editor",
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    width = width,
    height = height,
    border = "rounded",
    style = "minimal",
    title = " LLM補足文 ",
    title_pos = "center",
    footer = " Enter: カーソル位置に挿入  /  q・Esc: 閉じる ",
    footer_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local function cancel()
    close_preview(win, source_win)
  end
  local function insert()
    close_preview(win, source_win)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(source_win) then
      return
    end
    local row, col = cursor[1] - 1, cursor[2]
    vim.api.nvim_buf_set_text(buf, row, col, row, col, lines)
  end
  vim.keymap.set("n", "<CR>", insert, { buffer = preview, nowait = true, silent = true })
  vim.keymap.set("n", "q", cancel, { buffer = preview, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = preview, nowait = true, silent = true })
end

local function start(buf)
  if states[buf] then
    return
  end
  local state = { status = "running" }
  states[buf] = state
  vim.keymap.set("n", "<leader>gm", function()
    M.preview(buf)
  end, { buffer = buf, desc = "Commit: preview generated message" })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      states[buf] = nil
      if state.process and state.status == "running" then
        pcall(state.process.kill, state.process, 15)
      end
    end,
  })

  state.process = vim.system({
    vim.v.progpath,
    "--clean",
    "--headless",
    "+lua vim.env.NVIM_COMMIT_MSG_MODE = 'llm'; dofile(vim.fn.stdpath('config') .. '/scripts/generate-commit-msg.lua')",
    "+qa",
  }, { cwd = vim.fn.getcwd(), text = true }, function(result)
    vim.schedule(function()
      if states[buf] ~= state or not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local message = (result.stdout or ""):gsub("\r\n", "\n"):gsub("\n+$", "")
      if result.code ~= 0 or result.signal ~= 0 or message == "" or message == "変更がありません" then
        state.status = "failed"
        local detail = (result.stderr or ""):match("[^\r\n]+")
        vim.notify("LLM補足文を生成できませんでした" .. (detail and ": " .. detail or ""), vim.log.levels.WARN)
        return
      end
      state.lines = vim.split(message, "\n", { plain = true })
      state.status = "ready"
      vim.notify("LLM補足文ができました。<Space>gm で確認できます", vim.log.levels.INFO)
    end)
  end)
end

function M.setup()
  if vim.env.NVIM_GENERATE_COMMIT_MSG ~= "1" then
    return
  end
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function(args)
      if vim.bo[args.buf].buftype == "" then
        start(args.buf)
      end
    end,
  })
end

return M
