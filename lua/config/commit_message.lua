local M = {}

local states = {}
local generated_editors = {}

local attach, result_message, notify_failure

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
    footer = state.inserted and " 本文に挿入済み  /  Enter・q・Esc: 閉じる "
      or " Enter: カーソル位置に挿入  /  q・Esc: 閉じる ",
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
  vim.keymap.set("n", "<CR>", state.inserted and cancel or insert, { buffer = preview, nowait = true, silent = true })
  vim.keymap.set("n", "q", cancel, { buffer = preview, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = preview, nowait = true, silent = true })
end

function M.generate(mode, cwd, callback, opts)
  return vim.system({
    vim.v.progpath,
    "--clean",
    "--headless",
    "+lua dofile(vim.fn.stdpath('config') .. '/scripts/generate-commit-msg.lua')",
    "+qa",
  }, {
    cwd = cwd,
    env = {
      NVIM_COMMIT_MSG_MODE = mode,
      NVIM_COMMIT_MSG_STAGED_ONLY = opts and opts.staged_only and "1" or "0",
    },
    text = true,
  }, callback)
end

-- Compose the same rule + LLM body as full mode, keeping the rule on failure.
-- The caller supplies a callback so neither child Neovim blocks the UI.
function M.prepare(mode, cwd, callback)
  M.generate("rule", cwd, vim.schedule_wrap(function(result)
    local message = result_message(result)
    if not message then
      if result.code == 0 and vim.trim(result.stdout or "") == "変更がありません" then
        vim.notify("ステージ済みの変更がありません", vim.log.levels.INFO)
      else
        notify_failure("コミットメッセージを生成できませんでした", result)
      end
      callback(nil)
      return
    end
    if mode == "rule" then
      callback(message)
      return
    end
    vim.notify("LLM補足文を生成中です", vim.log.levels.INFO)
    M.generate("llm", cwd, vim.schedule_wrap(function(llm_result)
      local supplement = result_message(llm_result)
      if not supplement then
        notify_failure("LLM補足文を生成できませんでした。ルールベースのメッセージを使用します", llm_result)
      end
      callback(message .. (supplement and "\n\n" .. supplement or ""), supplement)
    end), { staged_only = true })
  end), { staged_only = true })
end

-- Mark this editor before FileType fires, including the legacy environment hook.
-- <leader>gm reuses the completed supplement; it never starts another LLM.
function M.generated_editor(path, supplement)
  path = vim.fs.normalize(path)
  generated_editors[path] = { supplement = supplement }
  local autocmd = vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function(args)
      if vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf)) == path then
        M.start(args.buf)
      end
    end,
  })
  return function()
    generated_editors[path] = nil
    pcall(vim.api.nvim_del_autocmd, autocmd)
  end
end

function M.start(buf, cwd)
  if states[buf] then
    return
  end
  local generated = generated_editors[vim.fs.normalize(vim.api.nvim_buf_get_name(buf))]
  if generated then
    attach(buf, {
      status = generated.supplement and "ready" or "disabled",
      lines = generated.supplement and vim.split(generated.supplement, "\n", { plain = true }),
      inserted = true,
    })
    return
  end
  local state = { status = "running" }
  attach(buf, state)

  local subject = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  if subject and subject ~= "" then
    subject = subject:gsub("%s+$", "") .. " "
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { subject })
    local win = vim.api.nvim_get_current_win()
    vim.wo[win].virtualedit = "onemore"
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_win_set_cursor(win, { 1, #subject })
      end
    end)
  end

  state.process = M.generate("llm", cwd, function(result)
    vim.schedule(function()
      if states[buf] ~= state or not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local message = result_message(result)
      if not message then
        state.status = "failed"
        notify_failure("LLM補足文を生成できませんでした", result)
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
        M.start(args.buf, vim.fn.getcwd())
      end
    end,
  })
end

attach = function(buf, state)
  states[buf] = state
  if state.status ~= "disabled" then
    vim.keymap.set("n", "<leader>gm", function()
      M.preview(buf)
    end, { buffer = buf, desc = "Commit: preview generated message" })
  end
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
end

result_message = function(result)
  local message = (result.stdout or ""):gsub("\r\n", "\n"):gsub("\n+$", "")
  if result.code == 0 and result.signal == 0 and message ~= "" and message ~= "変更がありません" then
    return message
  end
end

notify_failure = function(label, result)
  local detail = (result.stderr or ""):match("[^\r\n]+")
  vim.notify(label .. (detail and ": " .. detail or ""), vim.log.levels.WARN)
end

return M
