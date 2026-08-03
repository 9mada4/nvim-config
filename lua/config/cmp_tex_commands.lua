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

local citation_commands = {
  autocite = true,
  Autocite = true,
  cite = true,
  Cite = true,
  citealp = true,
  citealt = true,
  citeauthor = true,
  Citeauthor = true,
  citep = true,
  citet = true,
  citeyear = true,
  citeyearpar = true,
  footcite = true,
  nocite = true,
  parencite = true,
  Parencite = true,
  smartcite = true,
  Smartcite = true,
  supercite = true,
  textcite = true,
  Textcite = true,
}

local include_commands = {
  "include",
  "input",
  "subfile",
}

local bibliography_commands = {
  "addbibresource",
  "addglobalbib",
  "addsectionbib",
  "bibliography",
  "defaultbibliography",
  "nobibliography",
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

local graphics_extensions = {
  eps = true,
  jpeg = true,
  jpg = true,
  pdf = true,
  png = true,
  svg = true,
}

local tex_file_extensions = { tex = true }
local bibliography_file_extensions = { bib = true }
local workspace_file_commands = {
  addbibresource = bibliography_file_extensions,
  addglobalbib = bibliography_file_extensions,
  addsectionbib = bibliography_file_extensions,
  bibliography = bibliography_file_extensions,
  defaultbibliography = bibliography_file_extensions,
  include = tex_file_extensions,
  input = tex_file_extensions,
  nobibliography = bibliography_file_extensions,
  subfile = tex_file_extensions,
}

local ignored_workspace_directories = {
  [".git"] = true,
  [".hg"] = true,
  [".svn"] = true,
  [".venv"] = true,
  ["__pycache__"] = true,
  ["node_modules"] = true,
  ["vendor"] = true,
}

local workspace_file_cache = {}
local uv = vim.uv or vim.loop

local function split_path_prefix(path_prefix)
  local dir_prefix, name_prefix = path_prefix:match("^(.*[/])([^/]*)$")

  if dir_prefix == nil then
    return "", path_prefix
  end

  return dir_prefix, name_prefix
end

local function expand_path_dir(dir_prefix)
  if dir_prefix:sub(1, 1) == "/" then
    return dir_prefix
  end

  if dir_prefix:sub(1, 2) == "~/" then
    return vim.fn.expand("~") .. dir_prefix:sub(2)
  end

  return vim.fs.normalize(vim.fs.joinpath(vim.fn.getcwd(), dir_prefix))
end

local function path_item(path_prefix, name, fs_type, filter_text, text_edit_range)
  local is_directory = fs_type == "directory"
  local insert_text = path_prefix .. name .. (is_directory and "/" or "")

  return {
    label = insert_text,
    filterText = filter_text or name,
    insertText = insert_text,
    insertTextFormat = 1,
    kind = is_directory and 19 or 17,
    detail = is_directory and "directory" or "file",
    textEdit = text_edit_range and {
      newText = insert_text,
      range = text_edit_range,
    } or nil,
  }
end

local function workspace_path_text_edit_range(params, path_prefix, path_suffix)
  local cursor = params.context.cursor

  return {
    start = {
      line = cursor.row - 1,
      character = cursor.col - 1 - #path_prefix,
    },
    ["end"] = {
      line = cursor.row - 1,
      character = cursor.col - 1 + #path_suffix,
    },
  }
end

local function is_workspace_file_candidate(name, fs_type, allowed_extensions)
  if fs_type == "directory" then
    return true
  end

  local extension = name:match("%.([^./]+)$")
  return extension ~= nil and allowed_extensions[extension:lower()] == true
end

local function should_skip_workspace_directory(path, include_hidden)
  for segment in path:gmatch("[^/\\]+") do
    if ignored_workspace_directories[segment] or (not include_hidden and segment:sub(1, 1) == ".") then
      return true
    end
  end

  return false
end

local function scan_workspace_entries(scan_dir, include_hidden, recursive)
  scan_dir = vim.fs.normalize(scan_dir)
  if vim.fn.isdirectory(scan_dir) ~= 1 then
    return {}
  end

  local cache_key = table.concat({
    scan_dir,
    include_hidden and "hidden" or "visible",
    recursive and "recursive" or "direct",
  }, "\0")
  local now = uv.now()
  local cached = workspace_file_cache[cache_key]

  if cached and now - cached.created_at < 2000 then
    return cached.entries
  end

  local entries = {}
  for name, fs_type in vim.fs.dir(scan_dir, {
    depth = recursive and 20 or 1,
    skip = function(directory_name)
      return not should_skip_workspace_directory(directory_name, include_hidden)
    end,
  }) do
    local is_immediate_directory = fs_type == "directory" and name:find("[/\\]") == nil
    local is_visible = include_hidden or not should_skip_workspace_directory(name, false)

    if is_visible and (is_immediate_directory or fs_type ~= "directory") then
      table.insert(entries, { name = name, fs_type = fs_type })
    end
  end

  workspace_file_cache[cache_key] = {
    created_at = now,
    entries = entries,
  }

  return entries
end

local function candidate_matches_prefix(name, prefix)
  if prefix == "" then
    return true
  end

  local lower_prefix = prefix:lower()
  return vim.startswith(name:lower(), lower_prefix)
    or vim.startswith(vim.fs.basename(name):lower(), lower_prefix)
end

local function complete_workspace_paths(params, path_prefix, path_suffix, allowed_extensions)
  local current_path = path_prefix .. path_suffix
  local dir_prefix, current_name = split_path_prefix(current_path)
  local _, name_prefix = split_path_prefix(path_prefix)
  local replacing_existing_path = path_suffix ~= "" or current_name:match("%.[^./]+$") ~= nil
  local candidate_prefix = replacing_existing_path and "" or name_prefix
  local scan_dir = expand_path_dir(dir_prefix)
  local workspace_root = vim.fs.normalize(vim.fn.getcwd())
  local recursive = vim.fs.relpath(workspace_root, vim.fs.normalize(scan_dir)) ~= nil

  local items = {}
  local include_hidden = candidate_prefix:sub(1, 1) == "."
  local text_edit_range = workspace_path_text_edit_range(params, path_prefix, path_suffix)

  for _, entry in ipairs(scan_workspace_entries(scan_dir, include_hidden, recursive)) do
    local name = entry.name
    local fs_type = entry.fs_type

    if is_workspace_file_candidate(name, fs_type, allowed_extensions)
      and candidate_matches_prefix(name, candidate_prefix)
    then
      local is_directory = fs_type == "directory"
      local filter_text = dir_prefix .. name .. (is_directory and "/" or "")

      if replacing_existing_path and path_prefix ~= "" then
        filter_text = path_prefix
      end

      table.insert(items, path_item(dir_prefix, name, fs_type, filter_text, text_edit_range))
    end
  end

  table.sort(items, function(left, right)
    if left.kind ~= right.kind then
      return left.kind == 19
    end

    return left.label:lower() < right.label:lower()
  end)

  return items
end

local function graphics_path_prefix(line)
  return line:match("\\includegraphics%[[^%]]*%]%{([^{}]*)$")
    or line:match("\\includegraphics%{([^{}]*)$")
end

local function workspace_path_suffix(line)
  return line:match("^([^{}]*)%}") or ""
end

local function workspace_file_path_prefix(line)
  local graphics_prefix = graphics_path_prefix(line)
  if graphics_prefix ~= nil then
    return graphics_prefix, graphics_extensions
  end

  local patterns = {
    "\\([%a]+)%*?%s*%{([^{}]*)$",
    "\\([%a]+)%*?%s*%b[]%s*%{([^{}]*)$",
    "\\([%a]+)%*?%s*%b[]%s*%b[]%s*%{([^{}]*)$",
  }

  for _, pattern in ipairs(patterns) do
    local command, path_prefix = line:match(pattern)
    local allowed_extensions = command and workspace_file_commands[command]

    if allowed_extensions then
      return path_prefix, allowed_extensions
    end
  end

  return nil, nil
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

local function resolve_bib_path(base_dir, bib_path)
  local clean_path = vim.trim(bib_path)

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
    local bib_file = clean_path .. ".bib"

    if vim.fn.filereadable(bib_file) == 1 then
      return vim.fn.fnamemodify(bib_file, ":p")
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

local ignored_bib_entries = {
  comment = true,
  preamble = true,
  string = true,
}

local function add_bib_key(items, seen, key, entry_type, path, lnum)
  if seen[key] then
    return
  end

  seen[key] = true

  table.insert(items, {
    label = key,
    entry_type = entry_type,
    path = path,
    lnum = lnum,
    detail = entry_type .. " citation key",
  })
end

local function collect_bib_keys_from_lines(lines, path, items, seen)
  local pending_entry_type
  local pending_lnum

  for lnum, raw_line in ipairs(lines) do
    local line = strip_tex_comment(raw_line)
    local entry_type, key = line:match("@%s*([%a]+)%s*[%{%(%[]%s*([^,%s{}%)]+)%s*,")

    if entry_type and key then
      local normalized_entry_type = entry_type:lower()

      if not ignored_bib_entries[normalized_entry_type] then
        add_bib_key(items, seen, vim.trim(key), normalized_entry_type, path, lnum)
      end

      pending_entry_type = nil
      pending_lnum = nil
    else
      local header_entry_type = line:match("@%s*([%a]+)%s*[%{%(%[]%s*$")

      if header_entry_type then
        local normalized_entry_type = header_entry_type:lower()

        if ignored_bib_entries[normalized_entry_type] then
          pending_entry_type = nil
          pending_lnum = nil
        else
          pending_entry_type = normalized_entry_type
          pending_lnum = lnum
        end
      elseif pending_entry_type then
        local pending_key = line:match("^%s*([^,%s{}%)]+)%s*,")

        if pending_key then
          add_bib_key(items, seen, vim.trim(pending_key), pending_entry_type, path, pending_lnum or lnum)
          pending_entry_type = nil
          pending_lnum = nil
        elseif line:find("[{}%)]") then
          pending_entry_type = nil
          pending_lnum = nil
        end
      end
    end
  end
end

local function for_each_command_argument(line, command, callback)
  local patterns = {
    "\\" .. command .. "%*?%s*%{([^{}]+)%}",
    "\\" .. command .. "%*?%s*%b[]%s*%{([^{}]+)%}",
    "\\" .. command .. "%*?%s*%b[]%s*%b[]%s*%{([^{}]+)%}",
  }

  for _, pattern in ipairs(patterns) do
    for argument in line:gmatch(pattern) do
      callback(argument)
    end
  end
end

local function for_each_comma_value(argument, callback)
  for value in (argument .. ","):gmatch("%s*([^,]-)%s*,") do
    if value ~= "" then
      callback(value)
    end
  end
end

local function collect_project_bib_keys(bufnr)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local root_file = find_tex_root(bufnr)
  local items = {}
  local seen_keys = {}
  local seen_tex_files = {}
  local seen_bib_files = {}

  local function scan_bib_file(path)
    path = vim.fn.fnamemodify(path, ":p")

    if seen_bib_files[path] then
      return
    end

    seen_bib_files[path] = true

    local lines = read_lines_from_buffer_or_file(path)
    if lines then
      collect_bib_keys_from_lines(lines, path, items, seen_keys)
    end
  end

  local function scan_tex_file(path)
    path = vim.fn.fnamemodify(path, ":p")

    if seen_tex_files[path] then
      return
    end

    seen_tex_files[path] = true

    local lines = read_lines_from_buffer_or_file(path)
    if not lines then
      return
    end

    local base_dir = vim.fn.fnamemodify(path, ":p:h")
    for _, raw_line in ipairs(lines) do
      local line = strip_tex_comment(raw_line)

      for _, command in ipairs(bibliography_commands) do
        for_each_command_argument(line, command, function(argument)
          for_each_comma_value(argument, function(bib_path)
            local resolved_path = resolve_bib_path(base_dir, bib_path)

            if resolved_path then
              scan_bib_file(resolved_path)
            end
          end)
        end)
      end

      for _, command in ipairs(include_commands) do
        for include_path in line:gmatch("\\" .. command .. "%*?%{([^{}]+)%}") do
          local resolved_path = resolve_tex_path(base_dir, include_path)

          if resolved_path then
            scan_tex_file(resolved_path)
          end
        end
      end
    end
  end

  if root_file then
    scan_tex_file(root_file)
  end

  if current_file ~= "" then
    scan_tex_file(current_file)
  end

  return items
end

local function command_argument_prefix(line, command_set)
  local patterns = {
    "\\([%a]+)%*?%s*%{([^{}]*)$",
    "\\([%a]+)%*?%s*%b[]%s*%{([^{}]*)$",
    "\\([%a]+)%*?%s*%b[]%s*%b[]%s*%{([^{}]*)$",
  }

  for _, pattern in ipairs(patterns) do
    local command, argument = line:match(pattern)

    if command and command_set[command] then
      local active_argument = argument:match("([^,]*)$") or argument
      return vim.trim(active_argument)
    end
  end

  return nil
end

local function reference_argument_prefix(line)
  return command_argument_prefix(line, reference_commands)
end

local function citation_argument_prefix(line)
  return command_argument_prefix(line, citation_commands)
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

local function citation_item(spec, params, prefix)
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

local function complete_citations(params, prefix)
  local items = {}

  for _, spec in ipairs(collect_project_bib_keys(params.context.bufnr)) do
    if label_matches_prefix(spec.label, prefix) then
      table.insert(items, citation_item(spec, params, prefix))
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

  local citation_prefix = citation_argument_prefix(line)

  if citation_prefix ~= nil then
    callback({ items = complete_citations(params, citation_prefix), isIncomplete = false })
    return
  end

  if line:match("%$$") and is_opening_math_dollar(line) then
    callback({ items = { math_rm_item() }, isIncomplete = false })
    return
  end

  local path_prefix, allowed_extensions = workspace_file_path_prefix(line)

  if path_prefix ~= nil then
    local path_suffix = workspace_path_suffix(params.context.cursor_after_line or "")
    callback({
      items = complete_workspace_paths(params, path_prefix, path_suffix, allowed_extensions),
      isIncomplete = false,
    })
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
    or citation_argument_prefix(line) ~= nil
    or workspace_file_path_prefix(line) ~= nil
end

function M.should_complete_after_pair(line_before_cursor, line_after_cursor)
  if line_before_cursor:sub(-1) ~= "{" or line_after_cursor:sub(1, 1) ~= "}" then
    return false
  end

  return reference_argument_prefix(line_before_cursor) ~= nil
    or citation_argument_prefix(line_before_cursor) ~= nil
    or workspace_file_path_prefix(line_before_cursor) ~= nil
end

return M
