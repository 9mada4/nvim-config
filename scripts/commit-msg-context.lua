local M = {}

local context_max_bytes = 2048
local context_lines = 8

local function_nodes = {
  function_declaration = true,
  function_definition = true,
  function_expression = true,
  arrow_function = true,
  function_item = true,
  method_declaration = true,
  method_definition = true,
}

local section_nodes = {
  table_constructor = true,
  object = true,
  section = true,
  element = true,
  script_element = true,
  style_element = true,
  block_mapping_pair = true,
  table = true,
  table_array_element = true,
  class_declaration = true,
  class_definition = true,
}

local function snapshot(path, text)
  text = text:gsub("\r\n", "\n")
  local source = { lines = vim.split(text, "\n", { plain = true }) }
  if source.lines[#source.lines] == "" then
    table.remove(source.lines)
  end
  if text == "" then
    return source
  end

  -- The commit generator uses --clean, which omits user-installed parsers.
  local site = vim.fn.stdpath("data") .. "/site"
  if not vim.tbl_contains(vim.opt.runtimepath:get(), site) then
    vim.opt.runtimepath:append(site)
  end
  local filetype = vim.filetype.match({ filename = path })
  local aliases = { sh = "bash", zsh = "bash", javascriptreact = "javascript", typescriptreact = "tsx" }
  local language = aliases[filetype] or (filetype and vim.treesitter.language.get_lang(filetype))
  if language then
    local ok, parser = pcall(vim.treesitter.get_string_parser, text, language)
    if ok then
      local parsed, trees = pcall(parser.parse, parser)
      if parsed and trees[1] then
        source.root = trees[1]:root()
        source.parser = parser
      end
    end
  end
  return source
end

local function parse_hunks(diff)
  local hunks = {}
  local current, old_line, new_line
  for line in (diff .. "\n"):gmatch("(.-)\n") do
    local old_start, new_start = line:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
    if old_start then
      old_line, new_line = tonumber(old_start), tonumber(new_start)
      current = { lines = { line }, deleted = {}, added = {} }
      hunks[#hunks + 1] = current
    elseif current then
      local prefix = line:sub(1, 1)
      if prefix == "-" then
        current.deleted[#current.deleted + 1] = old_line
        old_line = old_line + 1
      elseif prefix == "+" then
        current.added[#current.added + 1] = new_line
        new_line = new_line + 1
      elseif prefix == " " then
        old_line, new_line = old_line + 1, new_line + 1
      elseif prefix ~= "\\" then
        current = nil
      end
      if current then
        current.lines[#current.lines + 1] = line
      end
    end
  end
  return hunks
end

local function enclosing_range(source, first, last)
  if not source.root then
    return nil
  end
  local first_col = (source.lines[first]:find("%S") or 1) - 1
  local last_col = math.max(0, #source.lines[last] - 1)
  local node = source.root:named_descendant_for_range(first - 1, first_col, last - 1, last_col)
  local section
  while node do
    if function_nodes[node:type()] then
      break
    end
    if not section and section_nodes[node:type()] then
      section = node
    end
    node = node:parent()
  end
  node = node or section
  if not node or node:has_error() then
    return nil
  end

  -- Keep the setting name / assignment around an anonymous function or table.
  local parent = node:parent()
  if parent and (parent:type() == "field" or parent:type() == "pair") then
    node = parent
  elseif parent and parent:type() == "expression_list" then
    local statement = parent:parent()
    if statement and statement:type() == "assignment_statement" then
      local declaration = statement:parent()
      node = declaration and declaration:type() == "variable_declaration" and declaration or statement
    end
  end
  local start_row, _, end_row, end_col = node:range()
  return { first = start_row + 1, last = end_row + (end_col > 0 and 1 or 0) }
end

local function ranges_for(source, changed, radius, structural)
  local ranges = {}
  local index = 1
  while index <= #changed do
    local first, last = changed[index], changed[index]
    index = index + 1
    while index <= #changed and changed[index] == last + 1 do
      last = changed[index]
      index = index + 1
    end
    if first >= 1 and last <= #source.lines then
      local range = structural and enclosing_range(source, first, last) or nil
      ranges[#ranges + 1] = range or {
        first = math.max(1, first - radius),
        last = math.min(#source.lines, last + radius),
      }
    end
  end
  table.sort(ranges, function(a, b)
    return a.first < b.first
  end)
  local merged = {}
  for _, range in ipairs(ranges) do
    local previous = merged[#merged]
    if previous and range.first <= previous.last then
      previous.last = math.max(previous.last, range.last)
    else
      merged[#merged + 1] = range
    end
  end
  local parts = {}
  for _, range in ipairs(merged) do
    parts[#parts + 1] = string.format("L%d-L%d:\n", range.first, range.last)
      .. table.concat(source.lines, "\n", range.first, range.last)
  end
  return table.concat(parts, "\n\n")
end

local function context(source, changed)
  local text = ranges_for(source, changed, context_lines, true)
  if #text <= context_max_bytes then
    return text
  end
  -- Large functions fall back to windows; the complete diff is kept separately.
  for radius = context_lines, 0, -1 do
    text = ranges_for(source, changed, radius, false)
    if #text <= context_max_bytes then
      return text
    end
  end
  return ""
end

function M.changes(file)
  local before = snapshot(file.old_path or file.path, file.before or "")
  local after = snapshot(file.path, file.after or "")
  local changes = {}
  for _, hunk in ipairs(parse_hunks(file.diff)) do
    if #hunk.deleted > 0 or #hunk.added > 0 then
      changes[#changes + 1] = {
        diff = table.concat(hunk.lines, "\n"),
        before = context(before, hunk.deleted),
        after = context(after, hunk.added),
      }
    end
  end
  return changes
end

return M
