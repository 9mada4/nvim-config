-- Run with: nvim --clean --headless -i NONE -l tests/insert-undo.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/lua/?.lua;" .. package.path

local checks = 0
local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end

-- Preserve existing Ctrl mappings on Windows/Linux; add Command keys only on macOS.
for _, platform in ipairs({ "windows", "linux", "macos" }) do
  package.loaded["config.os"] = { is_macos = platform == "macos" }
  vim.keymap.set("i", "<C-z>", "existing-ctrl-z")
  vim.keymap.set("i", "<C-v>", "existing-ctrl-v")
  dofile(root .. "/lua/config/keymaps.lua")
  check(vim.fn.maparg("<C-z>", "i") == "existing-ctrl-z", platform .. ": Ctrl-Z preserved")
  check(vim.fn.maparg("<C-v>", "i") == "existing-ctrl-v", platform .. ": Ctrl-V preserved")
  check((vim.fn.maparg("<D-z>", "i") ~= "") == (platform == "macos"), platform .. ": Command-Z scope")
  check((vim.fn.maparg("<D-S-z>", "i") ~= "") == (platform == "macos"), platform .. ": Command-Shift-Z scope")
  for _, mode in ipairs({ "n", "v", "i", "t" }) do
    check(vim.fn.maparg("<D-v>", mode) == "", platform .. ": terminal paste preserved in " .. mode)
    if mode ~= "i" then
      check(vim.fn.maparg("<D-z>", mode) == "", platform .. ": no undo mapping in " .. mode)
      check(vim.fn.maparg("<D-S-z>", mode) == "", platform .. ": no redo mapping in " .. mode)
    end
  end
  check(vim.fn.maparg("u", "n") == "", platform .. ": normal undo preserved")
  check(vim.fn.maparg("<C-r>", "n") == "", platform .. ": normal redo preserved")
end
vim.keymap.del("i", "<C-z>")
vim.keymap.del("i", "<C-v>")

local input, callbacks = {}, {}
local completed = 0
local function keys(value)
  input[#input + 1] = value
end
local function step(callback)
  callbacks[#callbacks + 1] = callback
  keys("<Cmd>lua _G.insert_undo_step(" .. #callbacks .. ")<CR>")
end
_G.insert_undo_step = function(index)
  callbacks[index]()
  completed = completed + 1
end
local function expect(value, message)
  step(function()
    local actual = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    check(actual == value, message .. ": " .. vim.inspect(actual))
  end)
end
local function fresh()
  keys("<Esc>")
  step(function() vim.cmd("enew!") end)
end
local function inserting()
  step(function() check(vim.fn.mode() == "i", "Insert mode continues") end)
end

fresh()
keys("ihello<D-z>")
expect("", "Command-Z undoes the whole typed chunk")
inserting()
keys("<D-S-z>")
expect("hello", "Command-Shift-Z restores the typed chunk")
inserting()
keys("!<D-z>")
expect("hello", "typing after redo forms its own undo block")
keys("<D-z>")
expect("", "repeated undo reaches the preceding block")
keys("new<D-z>")
expect("", "typing after undo forms its own undo block")
keys("<D-S-z>")
expect("new", "redo follows the new undo branch")

fresh()
keys("ibefore<Esc>a")
-- nvim_paste is the entry point used for terminal bracketed paste.
step(function()
  check(vim.api.nvim_paste("PASTE\n日本語", true, -1), "terminal paste succeeds")
end)
expect("beforePASTE\n日本語", "multiline Unicode paste keeps its contents")
keys("<D-z>")
expect("before", "one Command-Z reverses the whole paste only")
inserting()
keys("<D-S-z>")
expect("beforePASTE\n日本語", "redo restores the whole paste")
keys("<Esc>u")
expect("before", "normal u still reverses the paste")
keys("<C-r>")
expect("beforePASTE\n日本語", "normal Ctrl-R still restores the paste")
keys("<Esc>")

-- Keep the entire Insert session in one feedkeys call so headless mode never
-- waits for external input between assertions.
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(table.concat(input), true, false, true), "xt", false)
_G.insert_undo_step = nil
check(completed == #callbacks, "all queued checks ran")
print(string.format("insert-undo: %d checks passed", checks))
