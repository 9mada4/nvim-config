-- generate-commit-msg.lua
-- Cross-platform replacement for scripts/generate-commit-msg.sh
-- Usage:
--   nvim --clean --headless +"lua dofile(vim.fn.stdpath('config') .. '/scripts/generate-commit-msg.lua')" +qa

local function systemlist(cmd)
  local out = vim.fn.systemlist(cmd)
  local code = vim.v.shell_error
  return out, code
end

-- vim.fn.system() replaces NUL bytes with SOH, so use vim.system() for Git's -z output.
local function system_raw(cmd)
  local result = vim.system(cmd, { text = false }):wait()
  if result.code ~= 0 or result.signal ~= 0 then
    return nil
  end
  return result.stdout or ""
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

local function basename(path)
  local name = vim.fn.fnamemodify(path, ":t")
  return name ~= "" and name or path
end

local function lower_ext(path)
  local ext = path:match("%.([^%.%/%\\]+)$")
  return ext and ext:lower() or ""
end

local function path_tail(path, parts)
  local chunks = {}
  for chunk in path:gmatch("[^/\\]+") do
    table.insert(chunks, chunk)
  end

  local start = math.max(1, #chunks - parts + 1)
  local tail = {}
  for i = start, #chunks do
    table.insert(tail, chunks[i])
  end

  return table.concat(tail, "/")
end

local function truncate_name(name)
  if #name <= 34 then
    return name
  end

  return name:sub(1, 31) .. "..."
end

local function make_display_names(paths)
  local basename_counts = {}
  for _, path in ipairs(paths) do
    local name = basename(path)
    basename_counts[name] = (basename_counts[name] or 0) + 1
  end

  local names = {}
  for _, path in ipairs(paths) do
    local name = basename(path)
    if basename_counts[name] and basename_counts[name] > 1 then
      name = path_tail(path, 2)
    end
    table.insert(names, truncate_name(name))
  end

  return names
end

local function join_names(names)
  if #names <= 1 then
    return names[1] or ""
  end

  if #names == 2 then
    return names[1] .. "と" .. names[2]
  end

  return table.concat(names, "、")
end

local function normalize_numstat_path(path)
  local renamed_to = path:match("=>%s*(.+)$")
  if renamed_to then
    return renamed_to:gsub("^%s+", ""):gsub("%s+$", "")
  end

  return path
end

local function parse_num(value)
  if value == "-" then
    return 0
  end

  return tonumber(value) or 0
end

local function split_nul(output)
  if output == "" then
    return {}
  end
  return vim.split(output, "\0", { plain = true, trimempty = true })
end

local function git_name_status(use_cached)
  local cmd = { "git", "diff", "--name-status", "-z" }
  if use_cached then
    cmd = { "git", "diff", "--cached", "--name-status", "-z" }
  end
  local output = system_raw(cmd)
  if not output then
    return nil
  end

  local values = split_nul(output)
  local items = {}
  local index = 1
  while index <= #values do
    local status = values[index]
    index = index + 1
    if status:match("^[RC]") then
      local old_path = values[index]
      local new_path = values[index + 1]
      if not old_path or not new_path then
        return nil
      end
      items[#items + 1] = { status = status, old_path = old_path, path = new_path }
      index = index + 2
    else
      local path = values[index]
      if not path then
        return nil
      end
      items[#items + 1] = { status = status, old_path = path, path = path }
      index = index + 1
    end
  end
  return items
end

local function git_name_only(use_cached)
  local cmd = { "git", "diff", "--name-only", "-z" }
  if use_cached then
    cmd = { "git", "diff", "--cached", "--name-only", "-z" }
  end
  local output = system_raw(cmd)
  if not output then
    return nil
  end
  return split_nul(output)
end

local function get_numstat(use_cached)
  local cmd = { "git", "diff", "--numstat" }
  if use_cached then
    cmd = { "git", "diff", "--cached", "--numstat" }
  end

  table.insert(cmd, "-z")
  local output = system_raw(cmd)
  if not output then
    return {}
  end

  local stats = {}
  for _, line in ipairs(split_nul(output)) do
    local added, deleted, path = line:match("^([^\t]+)\t([^\t]+)\t(.*)$")
    if added and deleted and path then
      stats[normalize_numstat_path(path)] = parse_num(added) + parse_num(deleted)
    end
  end

  return stats
end

local code_exts = {
  c = true,
  cpp = true,
  go = true,
  h = true,
  java = true,
  js = true,
  jsx = true,
  lua = true,
  py = true,
  rs = true,
  ts = true,
  tsx = true,
}

local generated_or_lock_names = {
  ["lazy-lock.json"] = true,
  ["package-lock.json"] = true,
  ["pnpm-lock.yaml"] = true,
  ["yarn.lock"] = true,
}

local function file_score(path, stats)
  local ext = lower_ext(path)
  local score = 0

  if path == "init.lua" or path_starts_with(path, "lua/") then
    score = score + 95
  elseif path_starts_with(path, "scripts/") or has_ext(path, "sh") or has_ext(path, "cmd") or has_ext(path, "ps1") then
    score = score + 85
  elseif code_exts[ext] then
    score = score + 80
  elseif path_starts_with(path, ".github/") or path == ".gitlab-ci.yml" or path_starts_with(path, ".circleci/") then
    score = score + 75
  elseif has_ext(path, "json") or has_ext(path, "yaml") or has_ext(path, "yml") or has_ext(path, "toml") then
    score = score + 65
  elseif path == "README.md" or path_ends_with(path, "/README.md") then
    score = score + 60
  elseif path_starts_with(path, "docs/") or has_ext(path, "md") or has_ext(path, "txt") then
    score = score + 50
  else
    score = score + 40
  end

  if generated_or_lock_names[basename(path)] then
    score = score - 35
  end

  score = score + math.min(stats[path] or 0, 200) / 10
  return score
end

local function pick_main_paths(items, limit, stats)
  if #items <= limit then
    local paths = {}
    for _, item in ipairs(items) do
      table.insert(paths, item.path)
    end
    return paths
  end

  local scored = {}
  for index, item in ipairs(items) do
    table.insert(scored, {
      index = index,
      path = item.path,
      score = file_score(item.path, stats),
    })
  end

  table.sort(scored, function(a, b)
    if a.score == b.score then
      return a.index < b.index
    end
    return a.score > b.score
  end)

  local paths = {}
  for i = 1, math.min(limit, #scored) do
    table.insert(paths, scored[i].path)
  end

  return paths
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
  changes = git_name_status(true)
  files = git_name_only(true)
else
  vim.fn.system({ "git", "diff", "--quiet" })
  if vim.v.shell_error ~= 0 then
    changes = git_name_status(false)
    files = git_name_only(false)
  else
    print("変更がありません")
    os.exit(0)
  end
end

if not changes or not files then
  io.stderr:write("変更ファイルを読み込めませんでした\n")
  os.exit(1)
end

if is_empty(changes) or is_empty(files) then
  print("変更がありません")
  os.exit(0)
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
local has_copied = false

local first_target = ""
local changed_items = {}
local op_counts = {
  added = 0,
  copied = 0,
  deleted = 0,
  modified = 0,
  renamed = 0,
}

for _, change in ipairs(changes) do
  local status = change.status or ""
  local path1 = change.old_path or ""
  local path2 = change.path ~= path1 and change.path or ""

    local target = path1
    local op = "modified"
    if status:sub(1, 1) == "A" then
      has_added = true
      op = "added"
    elseif status:sub(1, 1) == "D" then
      has_deleted = true
      op = "deleted"
    elseif status:sub(1, 1) == "R" then
      has_renamed = true
      target = path2 ~= "" and path2 or path1
      op = "renamed"
    elseif status:sub(1, 1) == "C" then
      has_copied = true
      target = path2 ~= "" and path2 or path1
      op = "copied"
    elseif status:sub(1, 1) == "M" or status:sub(1, 1) == "C" then
      has_modified = true
    end

    op_counts[op] = (op_counts[op] or 0) + 1
    table.insert(changed_items, {
      old_path = path1,
      op = op,
      path = target,
      status = status,
    })

  if first_target == "" then
    first_target = target
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

local stats = get_numstat(use_staged)

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

local function subject_action()
  if op_counts.added > 0 and op_counts.modified == 0 and op_counts.deleted == 0 and op_counts.renamed == 0 then
    return "を追加"
  end

  if op_counts.deleted > 0 and op_counts.added == 0 and op_counts.modified == 0 and op_counts.renamed == 0 then
    return "を削除"
  end

  if op_counts.renamed > 0 and op_counts.added == 0 and op_counts.modified == 0 and op_counts.deleted == 0 then
    return "をリネーム"
  end

  if op_counts.added > 0 or op_counts.deleted > 0 or op_counts.renamed > 0 or op_counts.copied > 0 then
    return "を整理"
  end

  return "を更新"
end

local function op_label(op)
  if op == "added" then
    return "追加"
  elseif op == "deleted" then
    return "削除"
  elseif op == "renamed" then
    return "リネーム"
  elseif op == "copied" then
    return "コピー"
  end

  return "更新"
end

local function change_details(items)
  local paths = {}
  for _, item in ipairs(items) do
    table.insert(paths, item.path)
  end

  local names = make_display_names(paths)
  local details = {}
  for index, item in ipairs(items) do
    local name = names[index]
    if item.op == "renamed" and item.old_path ~= "" and item.old_path ~= item.path then
      name = basename(item.old_path) .. " -> " .. name
    end
    table.insert(details, name .. "(" .. op_label(item.op) .. ")")
  end

  return table.concat(details, "、")
end

local subject = ""
local body = {}
if count == 1 then
  local base = basename(first_target)
  if has_renamed then
    subject = base .. "をリネーム"
  elseif has_deleted then
    subject = base .. "を削除"
  elseif has_added then
    subject = base .. "を追加"
  elseif has_copied then
    subject = base .. "を追加"
  else
    if has_readme then
      subject = "READMEを更新"
    else
      subject = base .. "を更新"
    end
  end
else
  local subject_paths = pick_main_paths(changed_items, 3, stats)
  local names = make_display_names(subject_paths)
  local suffix = count > #subject_paths and "など" or ""
  subject = join_names(names) .. suffix .. subject_action()

  table.insert(body, "")
  table.insert(body, "更新内容: " .. change_details(changed_items))
end

local msg = prefix .. scope .. ": " .. subject
local output_mode = vim.env.NVIM_COMMIT_MSG_MODE or "full"
if output_mode == "rule" then
  local output = { msg }
  vim.list_extend(output, body)
  io.stdout:write(table.concat(output, "\n") .. "\n")
  return
end

local llm_summaries = {}
local selected_items
if count == 1 then
  selected_items = { changed_items[1] }
else
  local selected_paths = pick_main_paths(changed_items, 3, stats)
  local selected = {}
  for _, path in ipairs(selected_paths) do
    selected[path] = true
  end
  selected_items = {}
  for _, item in ipairs(changed_items) do
    if selected[item.path] then
      selected_items[#selected_items + 1] = item
    end
  end
end

local llm_inputs = {}
for _, item in ipairs(selected_items) do
  if item.op ~= "deleted" and item.op ~= "renamed" and item.op ~= "copied" then
    local cmd = { "git", "diff", "--no-ext-diff", "--no-textconv", "--unified=2" }
    if use_staged then
      table.insert(cmd, 3, "--cached")
    end
    vim.list_extend(cmd, { "--", item.path })
    local diff = vim.fn.system(cmd)
    if vim.v.shell_error == 0
      and #diff > 0
      and #diff <= 4096
      and not diff:find("\0", 1, true)
      and not diff:find("GIT binary patch", 1, true)
      and not diff:find("Binary files ", 1, true)
    then
      llm_inputs[#llm_inputs + 1] = {
        path = item.path,
        operation = item.op,
        diff = diff,
      }
    end
  end
end

if #llm_inputs > 0 then
  local helper_path = vim.fn.stdpath("config") .. "/scripts/commit-msg-llm.lua"
  local ok, helper = pcall(dofile, helper_path)
  if ok and type(helper) == "table" and type(helper.summarize) == "function" then
    local summarize_ok, summaries = pcall(helper.summarize, llm_inputs)
    if summarize_ok and type(summaries) == "table" then
      llm_summaries = summaries
    end
  end
end

local llm_text
if count == 1 then
  llm_text = llm_summaries.F1
else
  local extra = {}
  for index, item in ipairs(llm_inputs) do
    local summary = llm_summaries["F" .. tostring(index)]
    if summary then
      extra[#extra + 1] = basename(item.path) .. ": " .. summary
    end
  end
  if #extra > 0 then
    llm_text = "変更の補足: " .. table.concat(extra, "、")
  end
end

if output_mode == "llm" then
  if not llm_text then
    io.stderr:write("LLMの補足文を生成できませんでした\n")
    os.exit(2)
  end
  io.stdout:write(llm_text .. "\n")
  return
end

if llm_text then
  if count == 1 then
    msg = msg .. " — " .. llm_text
  else
    table.insert(body, "")
    table.insert(body, llm_text)
  end
end

local output = { msg }
for _, line in ipairs(body) do
  table.insert(output, line)
end
io.stdout:write(table.concat(output, "\n") .. "\n")
