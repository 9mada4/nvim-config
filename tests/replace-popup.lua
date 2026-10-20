-- Run with: nvim --clean --headless -l tests/replace-popup.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/lua/?.lua;" .. package.path

local popup = require("config.replace_popup")
local checks = 0
local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end

local function find_window(title)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if type(config.title) == "table" and config.title[1][1] == title then
      return win, vim.api.nvim_win_get_buf(win)
    end
  end
  error("window not found: " .. title)
end

local function key(buf, lhs)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if mapping.lhs == lhs then
      mapping.callback()
      return
    end
  end
  error("mapping not found: " .. lhs)
end

local function field(buf, value)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { value })
  vim.api.nvim_exec_autocmds("TextChangedI", { buffer = buf })
end

local source = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(source, 0, -1, false, { "α.foo and foo", "foo foo", "nope" })
vim.fn.setreg("/", "foo")
popup.open()
local _, search_buf = find_window(" 検索語 ")
local _, replace_buf = find_window(" 置換語 ")
local _, preview_buf = find_window(" 変更プレビュー ")
check(vim.api.nvim_buf_get_lines(search_buf, 0, 1, false)[1] == "foo", "simple previous search is prefilled")
field(replace_buf, "バー")
local preview = table.concat(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false), "\n")
check(preview:find("4 件一致", 1, true) ~= nil, "all matches appear")
check(preview:find("1:3", 1, true) ~= nil, "Unicode columns count characters")
local _, first_location_count = preview:gsub("1:3", "")
check(first_location_count == 2, "both before and after rows show the location")
check(preview:find("後", 1, true) and preview:find("バー", 1, true), "replacement preview appears")
key(preview_buf, "n")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "α.foo and foo", "n skips without changing text")
key(preview_buf, "y")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "α.foo and バー", "y replaces selected occurrence")
key(preview_buf, "a")
check(vim.deep_equal(vim.api.nvim_buf_get_lines(source, 0, -1, false), {
  "α.foo and バー", "バー バー", "nope",
}), "a replaces remaining occurrences and preserves skipped ones")

field(search_buf, ".")
field(replace_buf, "!")
preview = table.concat(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false), "\n")
check(preview:find("1 件一致", 1, true) ~= nil, "search uses literal text")
key(preview_buf, "a")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "α!foo and バー", "literal punctuation is replaced")
key(preview_buf, "q")

vim.api.nvim_buf_set_lines(source, 0, -1, false, { "a" })
vim.fn.setreg("/", "a")
popup.open()
_, replace_buf = find_window(" 置換語 ")
_, preview_buf = find_window(" 変更プレビュー ")
field(replace_buf, "aa")
key(preview_buf, "y")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "aa", "replacement containing search runs once")
key(preview_buf, "y")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "aa", "y does not reprocess its own result")
key(preview_buf, "q")

vim.api.nvim_buf_set_lines(source, 0, -1, false, { "foo foo" })
vim.fn.setreg("/", "foo")
popup.open()
_, replace_buf = find_window(" 置換語 ")
_, preview_buf = find_window(" 変更プレビュー ")
field(replace_buf, "bar")
key(preview_buf, "l")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "bar foo", "l replaces one occurrence and stops")
check(vim.api.nvim_get_current_buf() == source, "l returns to the source buffer")
vim.cmd("undo")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "foo foo", "normal-mode u restores a replacement after closing")

popup.open()
_, replace_buf = find_window(" 置換語 ")
_, preview_buf = find_window(" 変更プレビュー ")
field(replace_buf, "longer")
key(preview_buf, "y")
key(preview_buf, "a")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "longer longer", "separate single and batch changes apply")
key(preview_buf, "u")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "longer foo", "popup u reverses the whole batch")
key(preview_buf, "u")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "foo foo", "popup u can reverse the preceding single replacement")
key(preview_buf, "a")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "longer longer", "replacement still works after undo")
key(preview_buf, "q")
vim.cmd("undo")
check(vim.api.nvim_buf_get_lines(source, 0, 1, false)[1] == "foo foo", "normal-mode u reverses a batch as one operation")

print(string.format("replace-popup: %d checks passed", checks))
