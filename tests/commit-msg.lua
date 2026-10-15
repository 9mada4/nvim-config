-- Run with: nvim --clean --headless -l tests/commit-msg.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local real_dofile = dofile
local context = real_dofile(root .. "/scripts/commit-msg-context.lua")
local checks = 0

local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end

local function has(text, expected)
  return text:find(expected, 1, true) ~= nil
end

local function changes(path, before, after)
  return context.changes({
    path = path,
    before = before,
    after = after,
    diff = vim.diff(before, after, { result_type = "unified", ctxlen = 2 }),
  })
end

local first = "local function first()\n  local enabled = true\n  return enabled\nend\n"
local second = "local function second()\n  return 20\nend\n"
local before = first .. string.rep("\n", 8) .. second
local after = before:gsub("enabled = true", "enabled = false"):gsub("return 20", "return 30")
local result = changes("settings.lua", before, after)
check(#result == 2, "separate hunks must stay separate")
check(has(result[1].before, first:gsub("\n$", "")), "include the complete old function")
check(has(result[1].after, "local function first()"), "include the new function signature")
check(not has(result[1].after, "function second"), "exclude unrelated functions")
check(has(result[2].after, "local function second()"), "map the second hunk by line number")
check(has(result[1].diff, "-  local enabled = true\n+  local enabled = false"), "preserve diff ordering")
after = before:gsub("enabled = true", "enabled = false\n  local extra = 1"):gsub("return 20", "return 30")
result = changes("settings.lua", before, after)
check(#result == 2 and has(result[2].after, "local function second()"), "map hunks after inserted lines")
check(has(result[2].before, "return 20") and has(result[2].after, "return 30"), "keep old and new line numbers separate")

before = "local opts = {\n  completion = {\n    enabled = true,\n  },\n  unrelated = 42,\n}\n"
result = changes("settings.lua", before, before:gsub("enabled = true", "enabled = false"))
check(has(result[1].after, "completion = {"), "include the setting name around a nested table")
check(not has(result[1].after, "unrelated"), "use the smallest setting block")
result = changes("settings.lua", before:gsub("\n", "\r\n"), before:gsub("enabled = true", "enabled = false"):gsub("\n", "\r\n"))
check(has(result[1].after, "completion = {"), "extract setting blocks from CRLF snapshots")

before = '{\n  "completion": {\n    "enabled": true\n  },\n  "unrelated": 42\n}\n'
result = changes("settings.json", before, before:gsub("true", "false"))
check(has(result[1].after, '"completion": {'), "include the JSON key around an object")
check(not has(result[1].after, "unrelated"), "exclude unrelated JSON settings")

before = "# First\n\nOld paragraph.\n\n## Child\n\nOld child.\n\n# Second\n\nOther paragraph.\n"
result = changes("README.md", before, before:gsub("Old child", "New child"))
check(has(result[1].after, "## Child"), "include the Markdown section heading")
check(not has(result[1].after, "# Second"), "stop at the next Markdown section")

result = changes("deleted.lua", first, "")
check(has(result[1].before, "local function first()"), "use the old function for deletion")
check(result[1].after == "", "deletion has no new context")
result = changes("added.lua", "", first)
check(result[1].before == "", "addition has no old context")
check(has(result[1].after, "local function first()"), "use the new function for addition")

before = table.concat(vim.tbl_map(function(i)
  return "line " .. i
end, vim.fn.range(1, 30)), "\n") .. "\n"
result = changes("settings.unknown-extension", before, before:gsub("line 15\n", "changed 15\n"))
check(has(result[1].after, "line 7\n"), "missing parser falls back to surrounding lines")
check(not has(result[1].after, "line 1\n"), "fallback does not include the entire file")

before = "local function large()\n" .. string.rep("  -- unchanged context padding\n", 300) .. "  return 1\nend\n"
result = changes("large.lua", before, before:gsub("return 1", "return 2"))
check(#result[1].before <= 2048 and #result[1].after <= 2048, "bound large context blocks")
check(has(result[1].diff, "-  return 1\n+  return 2"), "keep the entire diff when context is reduced")
result = context.changes({ path = "example.lua", before = "return 1", after = "return 2",
  diff = "@@ -1 +1 @@\n-return 1\n\\ No newline at end of file\n+return 2\n\\ No newline at end of file\n" })
check(#result == 1 and has(result[1].after, "return 2"), "handle omitted hunk counts and no final newline")
check(#context.changes({ path = "renamed.lua", diff = "similarity index 100%\nrename from old.lua\nrename to renamed.lua\n" }) == 0,
  "rename without code changes has no hunks")

local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary, "p")
local original_cwd = vim.fn.getcwd()
local original_mode = vim.env.NVIM_COMMIT_MSG_MODE
local original_stdout = io.stdout
local original_exit = os.exit

local function git(args)
  local command = { "git", "-C", temporary }
  vim.list_extend(command, args)
  local response = vim.system(command, { text = true }):wait()
  assert(response.code == 0, response.stderr)
end

local function write(path, text)
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), temporary .. "/" .. path, "b")
end

local function generate(mode, inspect)
  local output = {}
  vim.env.NVIM_COMMIT_MSG_MODE = mode
  dofile = function(path)
    if path:match("/scripts/commit%-msg%-llm%.lua$") then
      return { summarize = function(files)
        inspect(files)
        local summaries = {}
        for index in ipairs(files) do
          summaries["F" .. index] = "処理の条件を変更した。\n設定値を変更した。"
        end
        return summaries
      end }
    end
    return real_dofile(path)
  end
  io.stdout = { write = function(_, text)
    output[#output + 1] = text
  end }
  os.exit = function(code)
    error("unexpected generator exit: " .. tostring(code))
  end
  vim.fn.chdir(temporary)
  real_dofile(root .. "/scripts/generate-commit-msg.lua")
  return table.concat(output)
end

local ok, failure = xpcall(function()
  git({ "init", "-q" })
  git({ "config", "user.name", "Commit message test" })
  git({ "config", "user.email", "test@example.invalid" })
  for _, path in ipairs({ "a.lua", "b.lua", "c.lua", "d.lua", "deleted.lua" }) do
    write(path, "return 1\n")
  end
  git({ "add", "." })
  git({ "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "commit", "-qm", "fixture" })
  for _, path in ipairs({ "a.lua", "b.lua", "c.lua", "d.lua" }) do
    write(path, "return 2\n")
  end
  write("added.lua", "return 4\n")
  git({ "rm", "-q", "deleted.lua" })
  git({ "add", "." })
  write("a.lua", "return 3\n")
  local output = generate("llm", function(files)
    check(#files == 6, "include every changed file, including additions and deletions")
    local found = {}
    for _, file in ipairs(files) do
      found[file.path] = file
    end
    check(found["a.lua"].before == "return 1\n", "staged before must come from HEAD")
    check(found["a.lua"].after == "return 2\n", "staged after must come from the index, not the worktree")
    check(found["added.lua"].before == "", "added file has an empty old snapshot")
    check(found["deleted.lua"].after == "", "deleted file has an empty new snapshot")
  end)
  check(has(output, "a.lua:\n処理の条件を変更した。\n設定値を変更した。\n\n") and has(output, "\n\nb.lua:\n"),
    "prefix each file and join sentences and files with newlines")
  local full = generate("full", function() end)
  check(not has(full:match("^[^\n]+"), "処理の条件"), "keep generated paragraphs out of the commit subject")
  check(has(full, "\n\na.lua:\n"), "full mode puts summaries in the body")
  git({ "reset", "--hard", "-q", "HEAD" })
  write("a.lua", "return 5\n")
  generate("llm", function(files)
    check(#files == 1 and files[1].before == "return 1\n", "unstaged before must come from the index")
    check(files[1].after == "return 5\n", "unstaged after must come from the worktree")
  end)
end, debug.traceback)

dofile = real_dofile
io.stdout = original_stdout
os.exit = original_exit
vim.env.NVIM_COMMIT_MSG_MODE = original_mode
vim.fn.chdir(original_cwd)
vim.fn.delete(temporary, "rf")
assert(ok, failure)
print(string.format("commit message: %d checks passed", checks))
