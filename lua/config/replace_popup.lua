local M = {}

local preview_ns = vim.api.nvim_create_namespace("replace_popup_preview")
local session

local function matches_for(buf, search)
  if search == "" then
    return {}
  end

  local matches = {}
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local from = 1
    while true do
      local first, last = line:find(search, from, true)
      if not first then
        break
      end
      matches[#matches + 1] = {
        row = row - 1,
        first = first - 1,
        last = last,
        column = vim.fn.strchars(line:sub(1, first - 1)) + 1,
        line = line,
      }
      from = last + 1
    end
  end
  return matches
end

local function input(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
end

local function context(line, first, last, replacement)
  local leading = line:sub(1, first)
  local before = vim.fn.strcharpart(leading, math.max(0, vim.fn.strchars(leading) - 24))
  local after = vim.fn.strcharpart(line:sub(last + 1), 0, 24)
  return before .. replacement .. after, #before
end

local function close()
  if not session then
    return
  end
  local current = session
  session = nil
  current.active = false
  if current.group then
    pcall(vim.api.nvim_del_augroup_by_id, current.group)
  end
  for _, win in ipairs(current.windows) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  if vim.api.nvim_win_is_valid(current.source_win) then
    vim.api.nvim_set_current_win(current.source_win)
  end
end

local function render(s)
  if not s.active or not vim.api.nvim_buf_is_valid(s.source_buf) then
    return
  end

  local search = input(s.search_buf)
  local replacement = input(s.replace_buf)
  s.matches = matches_for(s.source_buf, search)
  if s.selected ~= 0 then
    s.selected = math.min(math.max(s.selected, 1), math.max(#s.matches, 1))
  end

  local lines = {
    string.format("  %d 件一致  ·  現在のバッファ  ·  文字列として検索", #s.matches),
    "  j/k 選択   y/Enter 置換   n スキップ   a 残り全部",
    "  l 置換して終了   u 元に戻す   s 新規検索   e/E 入力編集   q 閉じる",
    "",
  }
  local highlights = {}
  if search == "" then
    lines[#lines + 1] = "  上の検索欄に置換前の文字を入力してください。"
  elseif #s.matches == 0 then
    lines[#lines + 1] = "  一致なし。s で次の検索・置換を開始できます。"
  else
    for index, match in ipairs(s.matches) do
      local marker = index == s.selected and "▶" or " "
      local location = string.format("%s %d:%d", marker, match.row + 1, match.column)
      local old, old_offset = context(match.line, match.first, match.last, search)
      local new, new_offset = context(match.line, match.first, match.last, replacement)
      local old_prefix = string.format("  %s  前  ", location)
      local new_prefix = string.format("  %s  後  ", location)
      lines[#lines + 1] = old_prefix .. old
      lines[#lines + 1] = new_prefix .. new
      highlights[#highlights + 1] = { #lines - 2, #old_prefix + old_offset, #search, "DiffDelete" }
      if replacement ~= "" then
        highlights[#highlights + 1] = { #lines - 1, #new_prefix + new_offset, #replacement, "DiffAdd" }
      end
      if index == s.selected then
        highlights[#highlights + 1] = { #lines - 2, 0, -1, "Visual" }
        highlights[#highlights + 1] = { #lines - 1, 0, -1, "Visual" }
      end
    end
  end

  vim.bo[s.preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(s.preview_buf, 0, -1, false, lines)
  vim.bo[s.preview_buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(s.preview_buf, preview_ns, 0, -1)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(s.preview_buf, preview_ns, highlight[1], highlight[2], {
      end_col = highlight[3] == -1 and #lines[highlight[1] + 1] or highlight[2] + highlight[3],
      hl_group = highlight[4],
      priority = highlight[4] == "Visual" and 10 or 20,
    })
  end
  if vim.api.nvim_win_is_valid(s.preview_win) then
    local target = #s.matches > 0 and s.selected > 0 and (5 + (s.selected - 1) * 2) or 1
    vim.api.nvim_win_set_cursor(s.preview_win, { target, 0 })
  end
end

local function edit(s, field)
  local win = field == "search" and s.search_win or s.replace_win
  vim.api.nvim_set_current_win(win)
  vim.cmd("startinsert!")
end

local function new_search(s)
  vim.api.nvim_buf_set_lines(s.search_buf, 0, -1, false, { "" })
  vim.api.nvim_buf_set_lines(s.replace_buf, 0, -1, false, { "" })
  s.selected = 1
  render(s)
  edit(s, "search")
end

local function undo_boundary(s)
  vim.api.nvim_buf_call(s.source_buf, function()
    vim.cmd("let &undolevels = &undolevels")
  end)
end

local function begin_change(s)
  local previous = s.undo_history[#s.undo_history]
  if previous and previous.tick ~= vim.api.nvim_buf_get_changedtick(s.source_buf) then
    s.undo_history = {}
  end
  undo_boundary(s)
end

local function finish_change(s, selected)
  undo_boundary(s)
  s.undo_history[#s.undo_history + 1] = {
    tick = vim.api.nvim_buf_get_changedtick(s.source_buf),
    selected = selected,
  }
end

local function undo_change(s)
  local last = s.undo_history[#s.undo_history]
  if not last then
    vim.notify("このポップアップで戻せる置換はありません", vim.log.levels.INFO)
    return
  end
  if last.tick ~= vim.api.nvim_buf_get_changedtick(s.source_buf) then
    s.undo_history = {}
    vim.notify("元のバッファが別途変更されたため、ポップアップからは戻せません", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(vim.api.nvim_buf_call, s.source_buf, function()
    vim.cmd("undo")
  end)
  if not ok then
    vim.notify("置換を戻せませんでした: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  table.remove(s.undo_history)
  local previous = s.undo_history[#s.undo_history]
  if previous then
    previous.tick = vim.api.nvim_buf_get_changedtick(s.source_buf)
  end
  s.selected = last.selected
  render(s)
end

local function replace_one(s)
  render(s)
  local match = s.matches[s.selected]
  if not match then
    return false
  end
  local search, replacement = input(s.search_buf), input(s.replace_buf)
  if search == replacement then
    vim.notify("検索語と置換語が同じです", vim.log.levels.WARN)
    return false
  end
  if not vim.bo[s.source_buf].modifiable then
    vim.notify("このバッファは編集できません", vim.log.levels.WARN)
    return false
  end

  local selected = s.selected
  begin_change(s)
  vim.api.nvim_buf_set_text(s.source_buf, match.row, match.first, match.row, match.last, { replacement })
  finish_change(s, selected)
  render(s)
  -- The replacement itself may contain the search text. Move past it.
  local next_byte = match.first + #replacement
  s.selected = 0
  for index, candidate in ipairs(s.matches) do
    if candidate.row > match.row or (candidate.row == match.row and candidate.first >= next_byte) then
      s.selected = index
      break
    end
  end
  render(s)
  return true
end

local function skip_one(s)
  render(s)
  if s.selected == 0 then
    return
  end
  s.selected = s.selected < #s.matches and s.selected + 1 or 0
  render(s)
end

local function replace_all(s)
  render(s)
  if #s.matches == 0 or s.selected == 0 then
    return
  end
  local search, replacement = input(s.search_buf), input(s.replace_buf)
  if search == replacement then
    vim.notify("検索語と置換語が同じです", vim.log.levels.WARN)
    return
  end
  if not vim.bo[s.source_buf].modifiable then
    vim.notify("このバッファは編集できません", vim.log.levels.WARN)
    return
  end

  local selected = s.selected
  local count = #s.matches - selected + 1
  begin_change(s)
  -- Work backwards so earlier byte columns remain valid, even on the same line.
  for index = #s.matches, selected, -1 do
    local match = s.matches[index]
    vim.api.nvim_buf_set_text(s.source_buf, match.row, match.first, match.row, match.last, { replacement })
  end
  finish_change(s, selected)
  s.selected = 1
  render(s)
  vim.notify(string.format("%d 件置換しました", count))
end

local function new_input_buffer(value)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { value })
  return buf
end

function M.open()
  close()
  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_get_current_buf()
  local last_search = vim.fn.getreg("/")
  local initial = vim.fn.escape(last_search, "\\.^$*[]~") == last_search and last_search or ""
  local width = math.min(110, vim.o.columns - 4)
  local height = math.min(22, vim.o.lines - vim.o.cmdheight - 10)
  if width < 34 or height < 5 then
    vim.notify("置換ポップアップを表示するには画面を広げてください", vim.log.levels.WARN)
    return
  end
  local row = math.max(1, math.floor((vim.o.lines - height - 6) / 2))
  local col = math.floor((vim.o.columns - width) / 2)
  local function window(buf, offset, size, title)
    local win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      row = row + offset,
      col = col,
      width = width,
      height = size,
      style = "minimal",
      border = "rounded",
      title = title,
      title_pos = "left",
      zindex = 60,
    })
    vim.wo[win].wrap = false
    return win
  end

  local search_buf = new_input_buffer(initial)
  local replace_buf = new_input_buffer("")
  local preview_buf = new_input_buffer("")
  local search_win = window(search_buf, 0, 1, " 検索語 ")
  local replace_win = window(replace_buf, 3, 1, " 置換語 ")
  local preview_win = window(preview_buf, 6, height, " 変更プレビュー ")
  local s = {
    active = true,
    source_win = source_win,
    source_buf = source_buf,
    search_buf = search_buf,
    replace_buf = replace_buf,
    preview_buf = preview_buf,
    search_win = search_win,
    replace_win = replace_win,
    preview_win = preview_win,
    windows = { search_win, replace_win, preview_win },
    selected = 1,
    matches = {},
    undo_history = {},
  }
  session = s

  s.group = vim.api.nvim_create_augroup("ReplacePopup" .. preview_buf, { clear = true })
  for _, buf in ipairs({ search_buf, replace_buf }) do
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = s.group,
      buffer = buf,
      callback = function()
        s.selected = 1
        render(s)
      end,
    })
  end
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = s.group,
    buffer = source_buf,
    callback = function()
      render(s)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = s.group,
    buffer = source_buf,
    callback = function()
      vim.schedule(function()
        if s.active then
          close()
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = s.group,
    callback = function(event)
      for _, win in ipairs(s.windows) do
        if tonumber(event.match) == win then
          vim.schedule(function()
            if s.active then
              close()
            end
          end)
          break
        end
      end
    end,
  })

  for _, buf in ipairs({ search_buf, replace_buf }) do
    vim.keymap.set({ "n", "i" }, "<Esc>", close, { buffer = buf, nowait = true })
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
    vim.keymap.set({ "n", "i" }, "<CR>", function()
      vim.cmd("stopinsert")
      vim.api.nvim_set_current_win(preview_win)
    end, { buffer = buf, nowait = true })
    vim.keymap.set({ "n", "i" }, "<Tab>", function()
      edit(s, buf == search_buf and "replace" or "search")
    end, { buffer = buf, nowait = true })
  end
  vim.keymap.set("n", "q", close, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "e", function() edit(s, "search") end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "E", function() edit(s, "replace") end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "s", function() new_search(s) end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "j", function()
    s.selected = math.min(s.selected + 1, #s.matches)
    render(s)
  end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "k", function()
    s.selected = math.max(s.selected - 1, 1)
    render(s)
  end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "y", function() replace_one(s) end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "<CR>", function() replace_one(s) end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "n", function() skip_one(s) end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "a", function() replace_all(s) end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "u", function() undo_change(s) end, { buffer = preview_buf, nowait = true })
  vim.keymap.set("n", "l", function()
    if replace_one(s) then
      close()
    end
  end, { buffer = preview_buf, nowait = true })

  render(s)
  edit(s, "search")
end

return M
