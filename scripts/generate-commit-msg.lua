-- generate-commit-msg.lua
-- Cross-platform replacement for scripts/generate-commit-msg.sh
-- Usage:
--   nvim --headless -l scripts/generate-commit-msg.lua

local function systemlist(cmd)
  local out = vim.fn.systemlist(cmd)
  local code = vim.v.shell_error
  return out, code
end

local function run_in_repo_root()
  local root_out, root_code = systemlist({ "git", "rev-parse", "--show-toplevel" })
  if root_code ~= 0 or not root_out[1] or root_out[1] == "" then
    io.stderr:write("Not inside a git repository\n")
    os.exit(1)
  end
  vim.fn.chdir(root_out[1])
end

local function is_empty(lines)
  return #lines == 0
end

local function path_starts_with(path, prefix)
  return path:sub(1, #prefix) == prefix
end

local function path_ends_with(path, suffix)
  return suffix == "" or path:sub(-#suffix) == suffix
end

local function has_ext(path, ext)
  return path_ends_with(path, "." .. ext)
end

run_in_repo_root()

local use_staged = false
vim.fn.system({ "git", "diff", "--cached", "--quiet" })
if vim.v.shell_error ~= 0 then
  use_staged = true
end

local changes
local files
if use_staged then
  changes = vim.fn.systemlist({ "git", "diff", "--cached", "--name-status" })
  files = vim.fn.systemlist({ "git", "diff", "--cached", "--name-only" })
else
  vim.fn.system({ "git", "diff", "--quiet" })
  if vim.v.shell_error ~= 0 then
    changes = vim.fn.systemlist({ "git", "diff", "--name-status" })
    files = vim.fn.systemlist({ "git", "diff", "--name-only" })
  else
    print("変更がありません")
    os.exit(1)
  end
end

if is_empty(changes) or is_empty(files) then
  print("変更がありません")
  os.exit(1)
end

local count = 0
for _, f in ipairs(files) do
  if f ~= "" then
    count = count + 1
  end
end

local has_readme = false
local has_docs = false
local has_ci = false
local has_build = false
local has_config = false
local has_script = false
local has_lua = false
local has_code = false

local has_added = false
local has_deleted = false
local has_renamed = false
local has_modified = false

local first_target = ""

for _, line in ipairs(changes) do
  if line ~= "" then
    local status, path1, path2 = line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)$")
    if not status then
      status, path1 = line:match("^([^\t]+)\t([^\t]+)$")
    end
    status = status or ""
    path1 = path1 or ""
    path2 = path2 or ""

    local target = path1
    if status:sub(1, 1) == "A" then
      has_added = true
    elseif status:sub(1, 1) == "D" then
      has_deleted = true
    elseif status:sub(1, 1) == "R" then
      has_renamed = true
      target = path2 ~= "" and path2 or path1
    elseif status:sub(1, 1) == "M" or status:sub(1, 1) == "C" then
      has_modified = true
    end

    if first_target == "" then
      first_target = target
    end
  end
end

for _, f in ipairs(files) do
  if f ~= "" then
    if f == "README.md" or path_ends_with(f, "/README.md") then
      has_readme = true
      has_docs = true
    elseif path_starts_with(f, "docs/") or has_ext(f, "md") or has_ext(f, "txt") then
      has_docs = true
    end

    if path_starts_with(f, ".github/") or f == ".gitlab-ci.yml" or path_starts_with(f, ".circleci/") then
      has_ci = true
    end

    if f == "package.json"
      or f == "package-lock.json"
      or f == "pnpm-lock.yaml"
      or f == "yarn.lock"
      or f == "Makefile"
      or f == "Dockerfile"
      or f == "docker-compose.yml"
      or f == "docker-compose.yaml"
      or has_ext(f, "toml")
    then
      has_build = true
    end

    if has_ext(f, "json")
      or has_ext(f, "yaml")
      or has_ext(f, "yml")
      or has_ext(f, "toml")
      or has_ext(f, "ini")
      or has_ext(f, "conf")
    then
      has_config = true
    end

    if path_starts_with(f, "scripts/") or has_ext(f, "sh") then
      has_script = true
    end

    if has_ext(f, "lua") or f == "init.lua" or path_starts_with(f, "lua/") then
      has_lua = true
      has_code = true
    elseif has_ext(f, "py")
      or has_ext(f, "js")
      or has_ext(f, "ts")
      or has_ext(f, "tsx")
      or has_ext(f, "jsx")
      or has_ext(f, "c")
      or has_ext(f, "cpp")
      or has_ext(f, "h")
      or has_ext(f, "java")
      or has_ext(f, "rs")
      or has_ext(f, "go")
    then
      has_code = true
    end
  end
end

local prefix = "chore"
if has_ci then
  prefix = "ci"
elseif has_build then
  prefix = "build"
elseif has_docs and (not has_code) and (not has_script) and (not has_lua) then
  prefix = "docs"
elseif has_added and has_code then
  prefix = "feat"
elseif has_code or has_script or has_lua then
  prefix = "chore"
elseif has_config then
  prefix = "chore"
end

local scope = ""
if has_lua then
  scope = "(nvim)"
elseif has_script then
  scope = "(scripts)"
elseif has_docs and has_readme then
  scope = "(readme)"
end

local subject = ""
if count == 1 then
  local base = vim.fn.fnamemodify(first_target, ":t")
  if has_renamed then
    subject = base .. "をリネーム"
  elseif has_deleted then
    subject = base .. "を削除"
  elseif has_added then
    subject = base .. "を追加"
  else
    if has_readme then
      subject = "READMEを更新"
    else
      subject = base .. "を更新"
    end
  end
else
  if has_renamed then
    subject = "複数ファイルを整理"
  elseif has_added and has_script then
    subject = "スクリプトを追加"
  elseif has_readme and has_script then
    subject = "READMEとスクリプトを更新"
  elseif has_docs and (not has_code) then
    subject = "文書を更新"
  elseif has_lua then
    subject = "Neovim設定を更新"
  else
    subject = "複数ファイルを更新"
  end
end

local msg = prefix .. scope .. ": " .. subject
print(msg)
