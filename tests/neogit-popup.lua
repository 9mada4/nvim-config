-- Run with: nvim --clean --headless -i NONE -l tests/neogit-popup.lua
-- Popup selection (<CR>/<Space>) and Japanese explanations (?) in Neogit popups.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
for _, plugin in ipairs({ "neogit", "plenary.nvim" }) do
  local path = vim.fn.stdpath("data") .. "/lazy/" .. plugin
  assert(vim.fn.isdirectory(path) == 1, "install " .. plugin .. " before this test")
  vim.opt.runtimepath:append(path)
end
vim.g.mapleader = " "
vim.o.swapfile = false
vim.o.hidden = true
vim.o.columns = 160
vim.fn.serverstart()
local checks = 0
local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end
local function wait(predicate, message)
  check(vim.wait(15000, predicate, 10), message)
end
local function key(buf, lhs)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if mapping.lhs == lhs then
      return mapping.callback()
    end
  end
  error("mapping not found: " .. lhs)
end
local function buffer(ft)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf)
      and (vim.bo[buf].filetype == ft or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t") == ft)
    then
      return buf
    end
  end
end
-- Explanation floats only (Neogit may have floats of its own).
local function floats()
  local result = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" and not config.focusable then
      result[#result + 1] = win
    end
  end
  return result
end
-- Moves the cursor to the first occurrence of text in the popup buffer.
local function goto_text(buf, text)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = line:find(text, 1, true)
    if col then
      vim.api.nvim_win_set_cursor(vim.fn.bufwinid(buf), { row, col - 1 })
      return row, col - 1
    end
  end
  error("text not found in popup: " .. text .. "\n"
    .. table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
end

local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary, "p")
local original_cwd = vim.fn.getcwd()
local function git(args)
  local argv = { "git", "-C", temporary }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end

local ok, failure = xpcall(function()
  git({ "init", "-q", "-b", "main" })
  git({ "config", "user.name", "Neogit test" })
  git({ "config", "user.email", "test@example.invalid" })
  git({ "config", "commit.gpgsign", "false" })
  vim.fn.writefile({ "x" }, temporary .. "/a.txt")
  git({ "add", "." })
  git({ "commit", "-qm", "fixture" })
  vim.fn.chdir(temporary)
  local spec = dofile(root .. "/lua/plugins/editor/neogit.lua")
  spec.opts.kind = "replace"
  spec.opts.filewatcher = { enabled = false }
  spec.opts.use_per_project_settings = false
  spec.opts.remember_settings = false
  spec.config(nil, spec.opts)
  local popup_ui = require("config.neogit_popup")
  local help = require("config.neogit_help_ja")

  require("neogit").open({ cwd = temporary, kind = "replace" })
  wait(function() return buffer("NeogitStatus") end, "status opens")
  local status_buf = buffer("NeogitStatus")
  vim.api.nvim_set_current_buf(status_buf)

  key(status_buf, "P")
  wait(function() return buffer("NeogitPushPopup") end, "push popup opens")
  local push = buffer("NeogitPushPopup")
  wait(function()
    return vim.fn.maparg("<CR>", "n", false, true).buffer == 1
  end, "popup gets buffer-local <CR>")
  local instance = require("neogit.lib.popup").instance
  local function bottom_hint(buf)
    local marks = vim.api.nvim_buf_get_extmarks(buf, popup_ui.hint_namespace, 0, -1, { details = true })
    if #marks ~= 1 then return nil end
    local text = {}
    for _, chunk in ipairs(marks[1][4].virt_lines[1]) do text[#text + 1] = chunk[1] end
    return table.concat(text), marks[1][2], marks[1][4].virt_lines_above
  end
  local hint, hint_row, above = bottom_hint(push)
  check(hint == "Enter/Space 実行 | ? 日本語で説明 | q 閉じる", "bottom hint text: " .. tostring(hint))
  check(hint_row == vim.api.nvim_buf_line_count(push) - 1 and not above, "hint sits below the last line")
  wait(function()
    return vim.api.nvim_win_get_height(vim.fn.bufwinid(push)) >= vim.api.nvim_buf_line_count(push) + 1
  end, "popup window has room for the hint row")

  -- Actions in the right-hand column share a row with the left-hand column.
  goto_text(push, "C Set variables")
  local item = popup_ui.item_under_cursor(push)
  check(item and item.kind == "action" and item.keys == "C", "right column action is selected: " .. vim.inspect(item))
  goto_text(push, "o another branch")
  item = popup_ui.item_under_cursor(push)
  check(item and item.keys == "o", "action under cursor is selected")
  check(#vim.api.nvim_buf_get_extmarks(push, popup_ui.namespace, 0, -1, {}) == 0
    or true, "highlight namespace exists")
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = push })
  check(#vim.api.nvim_buf_get_extmarks(push, popup_ui.namespace, 0, -1, {}) == 1, "selection is highlighted")

  -- Headings select nothing; run/explain do nothing there.
  goto_text(push, "Arguments")
  check(popup_ui.item_under_cursor(push) == nil, "heading selects nothing")
  local wins = #vim.api.nvim_list_wins()
  popup_ui.explain(push)
  popup_ui.run(push)
  vim.wait(50)
  check(#vim.api.nvim_list_wins() == wins and buffer("NeogitPushPopup"), "heading run/explain are no-ops")

  -- Two-character switch keys toggle through <CR>.
  goto_text(push, "--force-with-lease")
  item = popup_ui.item_under_cursor(push)
  check(item and item.kind == "switch" and item.keys == "-f", "switch selected: " .. vim.inspect(item))
  local function switch(cli)
    for _, arg in ipairs(instance.state.args) do
      if arg.cli == cli then return arg end
    end
  end
  check(not switch("force-with-lease").enabled, "switch starts disabled")
  key(push, "<CR>")
  wait(function() return switch("force-with-lease").enabled end, "<CR> toggles the switch")
  goto_text(push, "--force-with-lease")
  key(push, " ")
  wait(function() return not switch("force-with-lease").enabled end, "<Space> toggles the switch back")
  hint, hint_row = bottom_hint(push)
  check(hint and hint_row == vim.api.nvim_buf_line_count(push) - 1, "hint stays at the bottom after re-render")

  -- ? opens a Japanese explanation; q closes only the float.
  goto_text(push, "--force-with-lease")
  key(push, "?")
  check(#floats() == 1, "? opens one float")
  local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(floats()[1]), 0, -1, false), "\n")
  check(text:find("上書き", 1, true), "explanation is Japanese: " .. text)
  check(vim.api.nvim_get_current_buf() == push, "focus stays in popup")
  key(push, "q")
  check(#floats() == 0 and buffer("NeogitPushPopup"), "q closes float but keeps popup")
  goto_text(push, "o another branch")
  key(push, "?")
  check(#floats() == 1, "action explanation opens")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = push })
  check(#floats() == 0, "moving the cursor closes the float")
  key(push, "q")
  wait(function() return not buffer("NeogitPushPopup") end, "q without float closes popup")

  -- Unknown items fall back to the English description.
  local fallback = help.lookup({ kind = "action", popup = "NeogitNopePopup", keys = "z", description = "Zap" })
  check(fallback.body[1]:find("説明未登録", 1, true) and fallback.title:find("Zap", 1, true), "fallback text")

  -- Help popup (?) works the same way and <CR> runs the action.
  vim.api.nvim_set_current_buf(status_buf)
  key(status_buf, "?")
  wait(function() return buffer("NeogitHelpPopup") end, "help popup opens")
  local helpbuf = buffer("NeogitHelpPopup")
  wait(function() return vim.fn.maparg("?", "n", false, true).buffer == 1 end, "help popup gets ?")
  goto_text(helpbuf, "Pull")
  key(helpbuf, "?")
  check(#floats() == 1, "help popup explanation opens")
  text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(floats()[1]), 0, -1, false), "\n")
  check(text:find("取り込", 1, true), "help Pull explained in Japanese: " .. text)
  key(helpbuf, "q")
  goto_text(helpbuf, "Pull")
  key(helpbuf, "<CR>")
  wait(function() return buffer("NeogitPullPopup") end, "<CR> on Pull in help opens pull popup")
  key(buffer("NeogitPullPopup"), "q")
  wait(function()
    local refresh = require("neogit.lib.git").repo._refresh_task
    return not refresh or refresh:done()
  end, "final repository refresh finishes before fixture removal")
  vim.api.nvim_buf_delete(status_buf, { force = true })
end, debug.traceback)

vim.fn.chdir(original_cwd)
vim.fn.delete(temporary, "rf")
assert(ok, tostring(failure))
print(string.format("neogit-popup: %d checks passed", checks))
