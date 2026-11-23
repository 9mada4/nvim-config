-- Run with: nvim --clean --headless -i NONE -l tests/neogit.lua
-- Uses the installed Neogit/plenary and temporary repositories; no network calls.
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
local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary, "p")
local original_cwd = vim.fn.getcwd()
local function git(args)
  local argv = { "git", "-C", temporary }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end
local function write(path, text)
  vim.fn.writefile({ text }, temporary .. "/" .. path)
end
local notifications = {}
vim.notify = function(message)
  notifications[#notifications + 1] = message
end
local function notified(text)
  for _, message in ipairs(notifications) do
    if message:find(text, 1, true) then
      return true
    end
  end
  return false
end

local ok, failure = xpcall(function()
  git({ "init", "-q" })
  git({ "config", "user.name", "Neogit test" })
  git({ "config", "user.email", "test@example.invalid" })
  git({ "config", "commit.gpgsign", "false" })
  -- An empty hooks directory is portable to Windows, unlike /dev/null.
  vim.fn.mkdir(temporary .. "/no-hooks")
  git({ "config", "core.hooksPath", temporary .. "/no-hooks" })
  write("staged.lua", "return 1")
  write("unstaged.lua", "return 1")
  git({ "add", "." })
  git({ "commit", "-qm", "fixture" })
  -- Untracked files make the status buffer taller than the window.
  for i = 1, 60 do write(string.format("scroll%02d.txt", i), "x") end
  vim.fn.chdir(temporary)
  local spec = dofile(root .. "/lua/plugins/editor/neogit.lua")
  spec.opts.kind = "replace"
  spec.opts.commit_editor = { kind = "split", show_staged_diff = false }
  spec.opts.filewatcher = { enabled = false }
  spec.opts.use_per_project_settings = false
  spec.opts.remember_settings = false
  spec.config(nil, spec.opts)
  local neogit = require("neogit")
  local action_done = false
  local integration = require("config.neogit")
  local generated_commit = integration.commit
  integration.commit = function(mode)
    generated_commit(mode)
    action_done = true
  end
  local actions = require("neogit.popups.commit.actions")
  local standard_commit = actions.commit
  actions.commit = function(popup)
    standard_commit(popup)
    action_done = true
  end
  local commit_message = require("config.commit_message")
  local generate = commit_message.generate
  local llm_calls = 0
  local llm_fails = false
  local change_index = false
  commit_message.generate = function(mode, cwd, callback, opts)
    if opts then check(opts.staged_only, "Neogit generation always requests only staged changes") end
    if mode ~= "llm" then
      return generate(mode, cwd, callback, opts)
    end
    llm_calls = llm_calls + 1
    -- Test LLM integration deterministically without loading the model.
    vim.defer_fn(function()
      if change_index then
        write("staged.lua", "return 99")
        git({ "add", "staged.lua" })
      end
      callback({ code = llm_fails and 2 or 0, signal = 0,
        stdout = llm_fails and "" or "staged.lua:\n戻り値を変更した。\n",
        stderr = llm_fails and "fixture LLM failure" or "" })
    end, 30)
  end

  local function status()
    neogit.open({ cwd = temporary, kind = "replace" })
    wait(function() return buffer("NeogitStatus") end, "status opens")
    local buf = buffer("NeogitStatus")
    vim.api.nvim_set_current_buf(buf)
    return buf
  end
  local status_buf = status()
  wait(function()
    return #vim.api.nvim_buf_get_extmarks(status_buf,
      vim.api.nvim_create_namespace("nvim-config-neogit-hints"), 0, -1, {}) > 0
  end, "hints appear")
  local function hints()
    local marks = vim.api.nvim_buf_get_extmarks(status_buf,
      vim.api.nvim_create_namespace("nvim-config-neogit-hints"), 0, -1, { details = true })
    local lines = {}
    for _, chunks in ipairs(marks[1][4].virt_lines) do
      local text = {}
      for _, chunk in ipairs(chunks) do text[#text + 1] = chunk[1] end
      lines[#lines + 1] = table.concat(text)
    end
    return lines
  end
  check(hints()[1] == "Tab Diff | s Stage | u Unstage | c Commit | x Discard", "first hint matches keys: " .. vim.inspect(hints()))
  check(hints()[2] == "p Pull | P Push | Z Stash | ? Help | q Close", "second hint matches keys")
  check(vim.fn.winsaveview().topfill == 2, "both virtual hint rows are visible above the first buffer row")
  wait(function() return vim.api.nvim_buf_line_count(status_buf) > vim.api.nvim_win_get_height(0) end,
    "status lists enough files to scroll")
  vim.cmd("normal! G")
  vim.api.nvim_exec_autocmds("WinScrolled", {})
  check(vim.fn.winsaveview().topline > 1, "status scrolls past the hints")
  vim.cmd("normal! gg")
  vim.api.nvim_exec_autocmds({ "WinScrolled", "CursorMoved" }, { buffer = status_buf })
  check(vim.fn.winsaveview().topfill == 2, "hints return after scrolling back to top")
  if #vim.api.nvim_list_uis() > 0 then
    vim.cmd.redraw()
    local screen = {}
    for row = 1, 5 do
      local text = {}
      for col = 1, vim.o.columns do text[#text + 1] = vim.fn.screenstring(row, col) end
      screen[#screen + 1] = table.concat(text)
    end
    screen = table.concat(screen, "\n")
    check(screen:find(hints()[1], 1, true) and screen:find(hints()[2], 1, true), "both hint rows render on screen")
  end
  local config = require("neogit.config").values
  local defaults = require("neogit.config").get_default_values().mappings.status
  check(config.mappings.status.R == defaults.R and config.mappings.status.G == defaults.G,
    "R/G return to Neogit defaults")
  config.mappings.popup.p = nil
  config.mappings.popup["<leader>p"] = "PullPopup"
  require("config.neogit").update_hints(status_buf)
  check(hints()[2]:find("<leader>p Pull", 1, true), "hints derive keys from config")
  config.mappings.popup["<leader>p"] = nil
  config.mappings.popup.p = "PullPopup"
  require("config.neogit").update_hints(status_buf)

  for lhs, ft in pairs({ p = "NeogitPullPopup", P = "NeogitPushPopup", Z = "NeogitStashPopup" }) do
    vim.api.nvim_set_current_buf(status_buf)
    key(status_buf, lhs)
    wait(function() return buffer(ft) end, lhs .. " opens its standard popup")
    key(buffer(ft), "q")
  end

  local function commit(lhs, stage_all)
    action_done = false
    vim.api.nvim_set_current_buf(status_buf)
    key(status_buf, "c")
    wait(function() return buffer("NeogitCommitPopup") end, "c opens commit popup")
    local popup = buffer("NeogitCommitPopup")
    local contents = table.concat(vim.api.nvim_buf_get_lines(popup, 0, -1, false), "\n")
    check(contents:find("Generate (Rule)", 1, true) and contents:find("Generate (Rule + LLM)", 1, true),
      "both generation modes are visible in commit popup")
    for _, line in ipairs(vim.api.nvim_buf_get_lines(popup, 0, -1, false)) do
      local col = line:find("G Generate (Rule + LLM)", 1, true)
      if col then
        local finish = vim.fn.strdisplaywidth(line:sub(1, col - 1)) + #"G Generate (Rule + LLM)"
        check(finish <= 50, "generation column sits next to Create so narrow windows show it: ends at " .. finish)
      end
    end
    if stage_all then key(popup, "-a") end
    key(popup, lhs)
    return { done = function() return action_done end }
  end
  local function editor(task)
    wait(function() return buffer("gitcommit") or task:done() end, "commit reaches editor or returns")
    check(buffer("gitcommit"), "normal gitcommit editor opens")
    return buffer("gitcommit")
  end
  local function finish(task, buf, submit)
    key(buf, submit and "<C-C><C-C>" or "<C-C><C-K>")
    wait(function() return task:done() end, "commit action completes")
    check(not buffer("gitcommit"), "editor closes")
  end
  local function fixture()
    write("staged.lua", "return " .. tostring(checks))
    git({ "add", "staged.lua" })
    write("unstaged.lua", "return 42")
  end

  fixture()
  local original_env = vim.env.NVIM_GENERATE_COMMIT_MSG
  vim.env.NVIM_GENERATE_COMMIT_MSG = "1"
  local old_autocmds = {}
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "FileType", pattern = "gitcommit" })) do
    old_autocmds[autocmd.id] = true
  end
  commit_message.setup()
  vim.env.NVIM_GENERATE_COMMIT_MSG = original_env
  local head = git({ "rev-parse", "HEAD" })
  local task = commit("g", true)
  local buf = editor(task)
  check(llm_calls == 0, "c g never invokes LLM")
  check(git({ "rev-parse", "HEAD" }) == head, "generation alone never commits")
  check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("staged.lua", 1, true), "rule fills editor")
  check(not table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find("戻り値", 1, true), "rule has no LLM body")
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "test: 手動で確認・編集", "本文を2行目に書いた" })
  finish(task, buf, true)
  check(git({ "log", "-1", "--format=%s" }) == "test: 手動で確認・編集", "manual edits are committed")
  check(git({ "log", "-1", "--format=%b" }):find("^本文を2行目に書いた"), "blank line is inserted after the subject on submit")
  check(git({ "show", "HEAD:unstaged.lua" }) == "return 1", "generated commit ignores -a and excludes unstaged contents")

  fixture()
  head = git({ "rev-parse", "HEAD" })
  task = commit("G")
  -- Timers continue while asynchronous generation is pending.
  local responsive = false
  vim.schedule(function() responsive = true end)
  buf = editor(task)
  check(responsive, "Neovim processes scheduled work during generation")
  local contents = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  check(contents:find("staged.lua:\n戻り値を変更した。", 1, true), "c G inserts LLM body")
  check(llm_calls == 1 and git({ "rev-parse", "HEAD" }) == head, "full mode runs LLM once and waits for user")
  key(buf, " gm")
  check(llm_calls == 1, "preview reuses existing LLM result")
  key(vim.api.nvim_get_current_buf(), "<CR>")
  check(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") == contents,
    "Enter closes the already-inserted preview without duplicating the body")
  finish(task, buf, false)
  check(git({ "rev-parse", "HEAD" }) == head, "aborting generated editor does not commit")
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "FileType", pattern = "gitcommit" })) do
    if not old_autocmds[autocmd.id] then vim.api.nvim_del_autocmd(autocmd.id) end
  end

  llm_fails = true
  task = commit("G")
  buf = editor(task)
  check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("staged.lua", 1, true), "LLM failure keeps rule subject")
  check(notified("fixture LLM failure"), "LLM failure notifies user")
  finish(task, buf, true)
  check(git({ "rev-parse", "HEAD" }) ~= head, "LLM failure still allows manual commit")
  llm_fails = false

  fixture()
  change_index = true
  task = commit("G")
  wait(function() return task:done() end, "index change aborts generation")
  check(not buffer("gitcommit") and notified("生成中にステージ内容が変わりました"), "reject stale generated messages")
  change_index = false

  -- Standard c c remains the original action and still opens an editable buffer.
  commit_message.setup_subject_separator()
  task = commit("c")
  buf = editor(task)
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "test: 通常のコミット", "qで閉じた本文" })
  -- Save without the hook, then :q in the real Neogit editor window.
  vim.api.nvim_buf_call(buf, function() vim.cmd("silent noautocmd write") end)
  vim.api.nvim_set_current_win(vim.fn.bufwinid(buf))
  vim.cmd("quit")
  wait(function() return task:done() end, ":q completes the commit")
  check(git({ "log", "-1", "--format=%s" }) == "test: 通常のコミット", "standard c c unchanged")
  check(git({ "log", "-1", "--format=%b" }):find("^qで閉じた本文"), ":q in Neogit editor separates subject and body")
  for _, clean in ipairs({ false, true }) do
    if clean then git({ "restore", "." }) end
    local calls_before = llm_calls
    task = commit("G")
    wait(function() return task:done() end, "no staged changes returns")
    check(not buffer("gitcommit"), "unstaged-only/clean never opens a generated commit")
    check(llm_calls == calls_before, "unstaged-only/clean never invokes LLM")
  end
  check(notified("ステージ済みの変更がありません"), "explain missing staged changes")
  require("config.neogit").update_hints(status_buf)
  local marks = vim.api.nvim_buf_get_extmarks(status_buf,
    vim.api.nvim_create_namespace("nvim-config-neogit-hints"), 0, -1, {})
  check(#marks == 1 and marks[1][2] == 0, "status refresh retains exactly one header at row zero")
  -- Legacy external Git editors still generate in the background and insert
  -- the supplement only when the user accepts the preview.
  local legacy = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(legacy, temporary .. "/LEGACY_EDITMSG")
  vim.api.nvim_buf_set_lines(legacy, 0, -1, false, { "test: ルール文", "", "" })
  vim.api.nvim_set_current_buf(legacy)
  local calls_before = llm_calls
  commit_message.start(legacy, temporary)
  commit_message.start(legacy, temporary)
  wait(function() return notified("LLM補足文ができました") end, "legacy preview finishes")
  check(llm_calls == calls_before + 1, "legacy preview starts LLM only once per buffer")
  check(not table.concat(vim.api.nvim_buf_get_lines(legacy, 0, -1, false), "\n"):find("戻り値", 1, true),
    "legacy preview does not insert automatically")
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  key(legacy, " gm")
  key(vim.api.nvim_get_current_buf(), "<CR>")
  check(table.concat(vim.api.nvim_buf_get_lines(legacy, 0, -1, false), "\n"):find("戻り値を変更した。", 1, true),
    "legacy preview Enter still inserts at the cursor")
  vim.api.nvim_buf_delete(legacy, { force = true })
  -- :q on an unchanged commit buffer still separates subject and body on disk.
  commit_message.setup_subject_separator()
  local quit_path = temporary .. "/QUIT_EDITMSG"
  vim.fn.writefile({ "test: 件名", "本文", "# comment" }, quit_path)
  vim.cmd.edit(vim.fn.fnameescape(quit_path))
  local quit_buf = vim.api.nvim_get_current_buf()
  vim.bo[quit_buf].filetype = "gitcommit"
  vim.api.nvim_exec_autocmds("QuitPre", { buffer = quit_buf })
  check(vim.deep_equal(vim.fn.readfile(quit_path), { "test: 件名", "", "本文", "# comment" }),
    ":q writes the blank line after the subject")
  check(not vim.bo[quit_buf].modified, ":q leaves the buffer saved")
  vim.api.nvim_exec_autocmds("QuitPre", { buffer = quit_buf })
  check(#vim.fn.readfile(quit_path) == 4, "separator is inserted only once")
  vim.api.nvim_buf_set_lines(quit_buf, 0, -1, false, { "test: 件名", "# comment only" })
  vim.cmd("silent write")
  check(vim.deep_equal(vim.fn.readfile(quit_path), { "test: 件名", "# comment only" }),
    "comment on line 2 is left untouched")
  vim.api.nvim_buf_delete(quit_buf, { force = true })
  wait(function()
    local refresh = require("neogit.lib.git").repo._refresh_task
    return not refresh or refresh:done()
  end, "final repository refresh finishes before fixture removal")
end, debug.traceback)

vim.fn.chdir(original_cwd)
vim.fn.delete(temporary, "rf")
assert(ok, tostring(failure) .. "\nNotifications: " .. vim.inspect(notifications))
print(string.format("neogit: %d checks passed", checks))
