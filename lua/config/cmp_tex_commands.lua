local M = {}

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
  { name = "begin", label = "\\begin table booktabs", insert = "begin{table}[H]\n\\\\centering\n\\\\caption{${1:変更}}\n    \\\\begin{tabular}{l c}\n    \\\\toprule\n\t    項目 & 番号\\\\\\\\\n    \\\\midrule\n        い & 1\\\\\\\\\n        ろ & 2\\\\\\\\\n    \\\\bottomrule\n    \\\\end{tabular}\n\\\\label{table:$1}\n\\\\end{table}", detail = "booktabs table environment" },
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
  return { "\\", "{", "/", "." }
end

function source:complete(params, callback)
  local line = params.context.cursor_before_line
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

return M
