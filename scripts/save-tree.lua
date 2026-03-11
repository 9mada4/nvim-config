-- save-tree.lua
-- Cross-platform replacement for scripts/save-tree.sh
-- Usage:
--   nvim --headless -l scripts/save-tree.lua

local uv = vim.uv or vim.loop

local root = uv.cwd()

local sep = package.config:sub(1, 1)
local out_path = root .. sep .. "STRUCTURE.txt"

local exclude = {
  [".git"] = true,
  ["node_modules"] = true,
  [".DS_Store"] = true,
  ["lazy-lock.json"] = true,
}

local function join_path(a, b)
  if a:sub(-1) == sep then
    return a .. b
  end
  return a .. sep .. b
end

local function scandir(path)
  local fs = uv.fs_scandir(path)
  if not fs then
    return {}
  end

  local dirs = {}
  local files = {}

  while true do
    local name, t = uv.fs_scandir_next(fs)
    if not name then
      break
    end
    if not exclude[name] then
      if t == "directory" then
        table.insert(dirs, { name = name, type = t })
      else
        table.insert(files, { name = name, type = t })
      end
    end
  end

  table.sort(dirs, function(a, b)
    return a.name < b.name
  end)
  table.sort(files, function(a, b)
    return a.name < b.name
  end)

  local entries = {}
  for _, e in ipairs(dirs) do
    table.insert(entries, e)
  end
  for _, e in ipairs(files) do
    table.insert(entries, e)
  end
  return entries
end

local lines = {
  "Project tree",
  "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
  "",
  ".",
}

local function walk(path, prefix)
  local entries = scandir(path)
  for i, entry in ipairs(entries) do
    local is_last = i == #entries
    local branch = is_last and "└── " or "├── "
    table.insert(lines, prefix .. branch .. entry.name)

    if entry.type == "directory" then
      local next_prefix = prefix .. (is_last and "    " or "│   ")
      walk(join_path(path, entry.name), next_prefix)
    end
  end
end

walk(root, "")

local f, err = io.open(out_path, "w")
if not f then
  io.stderr:write("failed to write STRUCTURE.txt: " .. tostring(err) .. "\n")
  os.exit(1)
end
f:write(table.concat(lines, "\n"))
f:write("\n")
f:close()

print("saved: " .. out_path)
