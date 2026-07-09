local M = {}

local reference_commands = {
  autoref = true,
  Autoref = true,
  cref = true,
  Cref = true,
  eqref = true,
  nameref = true,
  pageref = true,
  ref = true,
  vref = true,
  Vref = true,
}

local include_commands = {
  "include",
  "input",
  "subfile",
}

local commands = {
  { name = "documentclass", insert = "documentclass[${1:uplatex, 11pt}]{${2:jsarticle}}", detail = "document class" },
  { name = "usepackage", insert = "usepackage{${1:package}}", detail = "package import" },
  { name = "graphicspath", insert = "graphicspath{{${1:Fig/}}}", detail = "graphics search path" },
  { name = "bibliographystyle", insert = "bibliographystyle{${1:unsrt}}", detail = "bibliography style" },
  { name = "bibliography", insert = "bibliography{${1:Ref/References}}", detail = "bibliography database" },
  { name = "defaultbibliographystyle", insert = "defaultbibliographystyle{${1:unsrt}}", detail = "bibunits bibliography style" },
  { name = "defaultbibliography", insert = "defaultbibliography{${1:Ref/References}}", detail = "bibunits bibliography database" },
  { name = "begin", insert = "begin{${1}}\n\t$0\n\\\\end{$1}", detail = "environment block" },
  { name = "begin", label = "\\begin figure textwidth", insert = "begin{figure}[H]\n    \\\\centering\n    \\\\includegraphics[width=1.0\\\\textwidth]{${1}}\n    \\\\caption{${2:変更図名}}\n    \\\\label{fig:${3:変更タグ}}\n\\\\end{figure}", detail = "figure environment with 1.0 textwidth image" },
  { name = "begin", label = "\\begin table booktabs", insert = "begin{table}[H]\n\\\\centering\n\\\\caption{${1:変更}}\n    \\\\begin{tabular}{l c}\n    \\\\toprule\n\t    項目 & 番号\\\\\\\\\n    \\\\midrule\n        い & 1\\\\\\\\\n        ろ & 2\\\\\\\\\n    \\\\bottomrule\n    \\\\end{tabular}\n\\\\label{table:${2:変更タグ}}\n\\\\end{table}", detail = "booktabs table environment" },
  { name = "end", insert = "end{${1}}", detail = "environment end" },
  { name = "section", insert = "section{${1:title}}", detail = "section" },
  { name = "subsection", insert = "subsection{${1:title}}", detail = "subsection" },
  { name = "subsubsection", insert = "subsubsection{${1:title}}", detail = "subsubsection" },
  { name = "paragraph", insert = "paragraph{${1:title}}", detail = "paragraph" },
  { name = "tableofcontents", detail = "table of contents" },
  { name = "newpage", detail = "new page" },
  { name = "input", insert = "input{${1:file}.tex}", detail = "input file" },
  { name = "include", insert = "include{${1:file}}", detail = "include file" },
  { name = "includegraphics", insert = "includegraphics[${1:width=0.8\\\\linewidth}]{${2:file}}", detail = "insert image" },
  { name = "caption", insert = "caption{${1:caption}}", detail = "caption" },
  { name = "label", insert = "label{${1:key}}", detail = "label" },
  { name = "ref", insert = "ref{${1:key}}", detail = "reference" },
  { name = "pageref", insert = "pageref{${1:key}}", detail = "page reference" },
  { name = "cite", insert = "cite{${1:key}}", detail = "citation" },
  { name = "footnote", insert = "footnote{${1:text}}", detail = "footnote" },
  { name = "putbib", detail = "bibunits bibliography output" },
  { name = "item", detail = "list item" },
  { name = "textbf", insert = "textbf{${1:text}}", detail = "bold text" },
  { name = "textit", insert = "textit{${1:text}}", detail = "italic text" },
  { name = "emph", insert = "emph{${1:text}}", detail = "emphasis" },
  { name = "underline", insert = "underline{${1:text}}", detail = "underline" },
  { name = "mathrm", insert = "mathrm{${1:text}}", detail = "roman text in math" },
  { name = "mathbf", insert = "mathbf{${1:text}}", detail = "bold text in math" },
  { name = "bm", insert = "bm{${1:symbol}}", detail = "bold math symbol" },
  { name = "frac", insert = "frac{${1:numerator}}{${2:denominator}}", detail = "fraction" },
  { name = "sqrt", insert = "sqrt{${1:value}}", detail = "square root" },
  { name = "sum", insert = "sum_{${1:i=1}}^{${2:n}}", detail = "summation" },
  { name = "int", insert = "int_{${1:a}}^{${2:b}}", detail = "integral" },
  { name = "left", insert = "left${1:(} $0 \\\\right${2:)}", detail = "paired delimiter" },
  { name = "right", detail = "right delimiter" },
  { name = "alpha", detail = "greek letter" },
  { name = "beta", detail = "greek letter" },
  { name = "gamma", detail = "greek letter" },
  { name = "delta", detail = "greek letter" },
  { name = "epsilon", detail = "greek letter" },
  { name = "theta", detail = "greek letter" },
  { name = "lambda", detail = "greek letter" },
  { name = "mu", detail = "greek letter" },
  { name = "pi", detail = "greek letter" },
  { name = "sigma", detail = "greek letter" },
  { name = "omega", detail = "greek letter" },
  { name = "Delta", detail = "greek letter" },
  { name = "Theta", detail = "greek letter" },
  { name = "Sigma", detail = "greek letter" },
  { name = "Omega", detail = "greek letter" },
  { name = "times", detail = "math operator" },
  { name = "cdot", detail = "math operator" },
  { name = "leq", detail = "math relation" },
  { name = "geq", detail = "math relation" },
  { name = "neq", detail = "math relation" },
  { name = "approx", detail = "math relation" },
}

local environment_snippets = {
  { name = "figure", insert = "begin{figure}[${1:H}]\n\t\\\\centering\n\t\\\\includegraphics[${2:width=0.8\\\\linewidth}]{${3:file}}\n\t\\\\caption{${4:caption}}\n\t\\\\label{fig:${5:label}}\n\\\\end{figure}", detail = "figure environment" },
  { name = "table", insert = "begin{table}[H]\n\t$0\n\\\\end{table}", detail = "table environment" },
  { name = "tabular", insert = "begin{tabular}{${1:c}}\n\t$0\n\\\\end{tabular}", detail = "tabular environment" },
  { name = "itemize", insert = "begin{itemize}\n\t\\\\item $0\n\\\\end{itemize}", detail = "itemize environment" },
  { name = "enumerate", insert = "begin{enumerate}\n\t\\\\item $0\n\\\\end{enumerate}", detail = "enumerate environment" },
  { name = "equation", insert = "begin{equation}\n\t$0\n\\\\end{equation}", detail = "equation environment" },
  { name = "align", insert = "begin{align}\n\t$0\n\\\\end{align}", detail = "align environment" },
  { name = "bibunit", insert = "begin{bibunit}\n\t$0\n\\\\putbib\n\\\\end{bibunit}", detail = "bibunit environment" },
}

local environment_names = {}
local seen_environment_names = {}

for _, spec in ipairs(environment_snippets) do
  if not seen_environment_names[spec.name] then
    table.insert(environment_names, spec.name)
    seen_environment_names[spec.name] = true
  end

  table.insert(commands, spec)
end

local source = {}

local function item_from_spec(spec)
  return {
    label = spec.label or "\\" .. spec.name,
    filterText = spec.filterText or spec.name,
    insertText = spec.insert or spec.name,
    insertTextFormat = 2,
    kind = 15,
    detail = spec.detail,
  }
end

local function environment_item(name)
  return {
    label = name,
    filterText = name,
    insertText = name,
    insertTextFormat = 1,
    kind = 15,
    detail = "LaTeX environment name",
  }
end

local function complete_environments(prefix)
  local items = {}
  local lower_prefix = prefix:lower()

  for _, name in ipairs(environment_names) do
    if prefix == "" or vim.startswith(name:lower(), lower_prefix) then
      table.insert(items, environment_item(name))
    end
  end

  return items
end

local function get_buffer_dir(params)
  local buffer_dir = vim.fn.expand(("#%d:p:h"):format(params.context.bufnr))

  if buffer_dir == "" then
    return vim.fn.getcwd()
  end

  return buffer_dir
end

local function split_path_prefix(path_prefix)
  local dir_prefix, name_prefix = path_prefix:match("^(.*[/])([^/]*)$")

  if dir_prefix == nil then
    return "", path_prefix
  end

  return dir_prefix, name_prefix
end

local function expand_path_dir(params, dir_prefix)
  if dir_prefix:sub(1, 1) == "/" then
    return dir_prefix
  end

  if dir_prefix:sub(1, 2) == "~/" then
    return vim.fn.expand("~") .. dir_prefix:sub(2)
  end

  return vim.fs.normalize(vim.fs.joinpath(get_buffer_dir(params), dir_prefix))
end

local function path_item(name, fs_type)
  local is_directory = fs_type == "directory"

  return {
    label = is_directory and name .. "/" or name,
    filterText = name,
    insertText = is_directory and name .. "/" or name,
    insertTextFormat = 1,
    kind = is_directory and 19 or 17,
    detail = is_directory and "directory" or "file",
  }
end

local function complete_graphics_paths(params, path_prefix)
  local dir_prefix, name_prefix = split_path_prefix(path_prefix)
  local scan_dir = expand_path_dir(params, dir_prefix)
  local fs = vim.loop.fs_scandir(scan_dir)

  if not fs then
    return {}
  end

  local items = {}
  local include_hidden = name_prefix:sub(1, 1) == "."
  local lower_prefix = name_prefix:lower()

  while true do
    local name, fs_type = vim.loop.fs_scandir_next(fs)

    if not name then
      break
    end

    if (include_hidden or name:sub(1, 1) ~= ".") and (name_prefix == "" or vim.startswith(name:lower(), lower_prefix)) then
      table.insert(items, path_item(name, fs_type))
    end
  end

  return items
end

local function graphics_path_prefix(line)
  return line:match("\\includegraphics%[[^%]]*%]%{([^{}]*)$")
    or line:match("\\includegraphics%{([^{}]*)$")
end

local function math_rm_item()
  return {
    label = "$\\mathrm{}$",
    filterText = "$",
    insertText = "\\mathrm{${1}}$",
    insertTextFormat = 2,
    kind = 15,
    detail = "inline math roman text",
  }
end

local function is_escaped_at(line, index)
  local backslash_count = 0
  local current = index - 1

  while current >= 1 and line:sub(current, current) == "\\" do
    backslash_count = backslash_count + 1
    current = current - 1
  end

  return backslash_count % 2 == 1
end

local function is_opening_math_dollar(line)
  local dollar_count = 0

  for index = 1, #line do
    if line:sub(index, index) == "$" and not is_escaped_at(line, index) then
      dollar_count = dollar_count + 1
    end
  end

  return dollar_count % 2 == 1
end

local function strip_tex_comment(line)
  for index = 1, #line do
    if line:sub(index, index) == "%" and not is_escaped_at(line, index) then
      return line:sub(1, index - 1)
    end
  end

  return line
end

local function read_lines_from_buffer_or_file(path)
  path = vim.fn.fnamemodify(path, ":p")

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p") == path then
      return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end
  end

  if vim.fn.filereadable(path) == 1 then
    return vim.fn.readfile(path)
  end

  return nil
end

local function read_current_buffer_lines(bufnr)
  if vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  return {}
end

local function tex_root_from_magic_comment(path, lines)
  if not path or path == "" then
    return nil
  end

  local current_dir = vim.fn.fnamemodify(path, ":p:h")

  for index = 1, math.min(#lines, 20) do
    local root = lines[index]:match("^%%%s*![Tt][Ee][Xx]%s+root%s*=%s*(.-)%s*$")
    if root and root ~= "" then
      if vim.fn.fnamemodify(root, ":p") == root then
        return root
      end

      return vim.fn.fnamemodify(vim.fs.joinpath(current_dir, root), ":p")
    end
  end

  return nil
end

local function find_tex_root(bufnr)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  if current_file == "" then
    return nil
  end

  local current_path = vim.fn.fnamemodify(current_file, ":p")
  local current_lines = read_current_buffer_lines(bufnr)
  local magic_root = tex_root_from_magic_comment(current_path, current_lines)

  if magic_root and vim.fn.filereadable(magic_root) == 1 then
    return vim.fn.fnamemodify(magic_root, ":p")
  end

  local current_dir = vim.fn.fnamemodify(current_path, ":p:h")
  local honshi = vim.fs.find("honshi.tex", {
    path = current_dir,
    upward = true,
    type = "file",
  })[1]

  if honshi then
    return vim.fn.fnamemodify(honshi, ":p")
  end

  return current_path
end

local function resolve_tex_path(base_dir, tex_path)
  local clean_path = vim.trim(tex_path)

  if clean_path == "" then
    return nil
  end

  if clean_path:sub(1, 2) == "~/" then
    clean_path = vim.fn.expand("~") .. clean_path:sub(2)
  elseif clean_path:sub(1, 1) ~= "/" then
    clean_path = vim.fs.joinpath(base_dir, clean_path)
  end

  clean_path = vim.fs.normalize(clean_path)

  if vim.fn.filereadable(clean_path) == 1 then
    return vim.fn.fnamemodify(clean_path, ":p")
  end

  if vim.fn.fnamemodify(clean_path, ":e") == "" then
    local tex_file = clean_path .. ".tex"

    if vim.fn.filereadable(tex_file) == 1 then
      return vim.fn.fnamemodify(tex_file, ":p")
    end
  end

  return nil
end

local function remove_environment(environment_stack, name)
  for index = #environment_stack, 1, -1 do
    if environment_stack[index] == name then
      table.remove(environment_stack, index)
      return
    end
  end
end

local function label_detail(label, environment)
  local prefix = label:match("^([^:]+):")

  if environment then
    if prefix then
      return prefix .. " label in " .. environment
    end

    return "label in " .. environment
  end

  if prefix then
    return prefix .. " label"
  end

  return "LaTeX label"
end

local function add_label(items, seen, label, environment, path, lnum)
  if seen[label] then
    return
  end

  seen[label] = true

  table.insert(items, {
    label = label,
    environment = environment,
    path = path,
    lnum = lnum,
    detail = label_detail(label, environment),
  })
end

local function collect_labels_from_lines(lines, path, items, seen)
  local environment_stack = {}

  for lnum, raw_line in ipairs(lines) do
    local line = strip_tex_comment(raw_line)
    local position = 1

    while position <= #line do
      local best_start
      local best_end
      local best_kind
      local best_value

      local begin_start, begin_end, begin_name = line:find("\\begin%{([%w*%-]+)%}", position)
      if begin_start and (not best_start or begin_start < best_start) then
        best_start = begin_start
        best_end = begin_end
        best_kind = "begin"
        best_value = begin_name
      end

      local end_start, end_end, end_name = line:find("\\end%{([%w*%-]+)%}", position)
      if end_start and (not best_start or end_start < best_start) then
        best_start = end_start
        best_end = end_end
        best_kind = "end"
        best_value = end_name
      end

      local label_start, label_end, label = line:find("\\label%{([^{}]+)%}", position)
      if label_start and (not best_start or label_start < best_start) then
        best_start = label_start
        best_end = label_end
        best_kind = "label"
        best_value = vim.trim(label)
      end

      if not best_start then
        break
      end

      if best_kind == "begin" then
        table.insert(environment_stack, best_value)
      elseif best_kind == "end" then
        remove_environment(environment_stack, best_value)
      elseif best_kind == "label" and best_value ~= "" then
        add_label(items, seen, best_value, environment_stack[#environment_stack], path, lnum)
      end

      position = best_end + 1
    end
  end
end

local function collect_project_labels(bufnr)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local root_file = find_tex_root(bufnr)
  local items = {}
  local seen_labels = {}

  if not root_file then
    collect_labels_from_lines(read_current_buffer_lines(bufnr), nil, items, seen_labels)
    return items
  end

  local seen_files = {}

  local function scan_file(path)
    path = vim.fn.fnamemodify(path, ":p")

    if seen_files[path] then
      return
    end

    seen_files[path] = true

    local lines = read_lines_from_buffer_or_file(path)
    if not lines then
      return
    end

    collect_labels_from_lines(lines, path, items, seen_labels)

    local base_dir = vim.fn.fnamemodify(path, ":p:h")
    for _, raw_line in ipairs(lines) do
      local line = strip_tex_comment(raw_line)

      for _, command in ipairs(include_commands) do
        for include_path in line:gmatch("\\" .. command .. "%*?%{([^{}]+)%}") do
          local resolved_path = resolve_tex_path(base_dir, include_path)

          if resolved_path then
            scan_file(resolved_path)
          end
        end
      end
    end
  end

  scan_file(root_file)

  if current_file ~= "" then
    scan_file(current_file)
  end

  return items
end

local function reference_argument_prefix(line)
  local command, argument = line:match("\\([%a]+)%*?%{([^{}]*)$")

  if not command or not reference_commands[command] then
    return nil
  end

  local active_argument = argument:match("([^,]*)$") or argument
  return vim.trim(active_argument)
end

local function label_matches_prefix(label, prefix)
  if prefix == "" then
    return true
  end

  return vim.startswith(label:lower(), prefix:lower())
end

local function label_item(spec, params, prefix)
  local cursor = params.context.cursor
  local start_character = cursor.col - 1 - #prefix

  return {
    label = spec.label,
    filterText = spec.label,
    insertTextFormat = 1,
    kind = 18,
    detail = spec.detail,
    documentation = spec.path and {
      kind = "markdown",
      value = ("`%s:%d`"):format(vim.fn.fnamemodify(spec.path, ":~:."), spec.lnum),
    } or nil,
    textEdit = {
      range = {
        start = {
          line = cursor.row - 1,
          character = start_character,
        },
        ["end"] = {
          line = cursor.row - 1,
          character = cursor.col - 1,
        },
      },
      newText = spec.label,
    },
  }
end

local function complete_labels(params, prefix)
  local items = {}

  for _, spec in ipairs(collect_project_labels(params.context.bufnr)) do
    if label_matches_prefix(spec.label, prefix) then
      table.insert(items, label_item(spec, params, prefix))
    end
  end

  table.sort(items, function(left, right)
    return left.label < right.label
  end)

  return items
end

function source:new()
  return setmetatable({}, { __index = self })
end

function source:is_available()
  return vim.bo.filetype == "tex" or vim.bo.filetype == "plaintex" or vim.bo.filetype == "latex"
end

function source:get_debug_name()
  return "tex_commands"
end

function source:get_trigger_characters()
  return { "\\", "{", "/", ".", "$", ":", "," }
end

function source:complete(params, callback)
  local line = params.context.cursor_before_line

  local label_prefix = reference_argument_prefix(line)

  if label_prefix ~= nil then
    callback({ items = complete_labels(params, label_prefix), isIncomplete = false })
    return
  end

  if line:match("%$$") and is_opening_math_dollar(line) then
    callback({ items = { math_rm_item() }, isIncomplete = false })
    return
  end

  local path_prefix = graphics_path_prefix(line)

  if path_prefix ~= nil then
    callback({ items = complete_graphics_paths(params, path_prefix), isIncomplete = false })
    return
  end

  local environment_prefix = line:match("\\begin%{([%w*%-]*)$") or line:match("\\end%{([%w*%-]*)$")

  if environment_prefix ~= nil then
    callback({ items = complete_environments(environment_prefix), isIncomplete = false })
    return
  end

  local prefix = line:match("\\([%a]*)$")

  if prefix == nil then
    callback({ items = {}, isIncomplete = false })
    return
  end

  local items = {}
  local lower_prefix = prefix:lower()
  for _, spec in ipairs(commands) do
    if prefix == "" or vim.startswith(spec.name:lower(), lower_prefix) then
      table.insert(items, item_from_spec(spec))
    end
  end

  callback({ items = items, isIncomplete = false })
end

function M.register()
  local cmp = require("cmp")

  for _, registered in ipairs(cmp.get_registered_sources()) do
    if registered.name == "tex_commands" then
      return
    end
  end

  cmp.register_source("tex_commands", source:new())
end

function M.is_reference_context(line)
  return reference_argument_prefix(line) ~= nil
end

return M
