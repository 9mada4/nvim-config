local build_group = vim.api.nvim_create_augroup("latex-auto-build", { clear = true })
local edit_group = vim.api.nvim_create_augroup("latex-edit-options", { clear = true })
local os = require("config.os")

local running = {}
local pending = {}

local function read_first_lines(bufnr, count)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local last = math.min(line_count, count)
  if last <= 0 then
    return {}
  end
  return vim.api.nvim_buf_get_lines(bufnr, 0, last, false)
end

local function tex_root_from_magic_comment(bufnr)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  if current_file == "" then
    return nil
  end

  local current_dir = vim.fn.fnamemodify(current_file, ":p:h")
  for _, line in ipairs(read_first_lines(bufnr, 20)) do
    local root = line:match("^%%%s*![Tt][Ee][Xx]%s+root%s*=%s*(.-)%s*$")
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
  local magic_root = tex_root_from_magic_comment(bufnr)
  if magic_root and vim.fn.filereadable(magic_root) == 1 then
    return magic_root
  end

  local current_file = vim.api.nvim_buf_get_name(bufnr)
  if current_file == "" then
    return nil
  end

  local current_dir = vim.fn.fnamemodify(current_file, ":p:h")
  local honshi = vim.fs.find("honshi.tex", {
    path = current_dir,
    upward = true,
    type = "file",
  })[1]

  if honshi then
    return vim.fn.fnamemodify(honshi, ":p")
  end

  return nil
end

local function set_quickfix_from_output(title, output)
  local lines = vim.split(output or "", "\n", { plain = true, trimempty = true })
  vim.fn.setqflist({}, "r", {
    title = title,
    lines = lines,
  })
end

local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO, { title = "LaTeX" })
  end)
end

local function missing_executables(commands)
  local missing = {}
  for _, command in ipairs(commands) do
    if vim.fn.executable(command) ~= 1 then
      table.insert(missing, command)
    end
  end
  return missing
end

local function clean_aux_files(root_file)
  local root_dir = vim.fn.fnamemodify(root_file, ":p:h")
  local root_base = vim.fn.fnamemodify(root_file, ":t:r")
  local root_aux_extensions = {
    "aux",
    "bbl",
    "blg",
    "idx",
    "ind",
    "lof",
    "lot",
    "out",
    "toc",
    "acn",
    "acr",
    "alg",
    "glg",
    "glo",
    "gls",
    "ist",
    "fls",
    "log",
    "fdb_latexmk",
    "synctex.gz",
    "nav",
    "snm",
    "vrb",
    "dvi",
  }

  for _, extension in ipairs(root_aux_extensions) do
    vim.fn.delete(vim.fs.joinpath(root_dir, root_base .. "." .. extension))
  end

  for _, pattern in ipairs({ "bu*.aux", "bu*.bbl", "bu*.blg", "_minted*" }) do
    for _, path in ipairs(vim.fn.glob(vim.fs.joinpath(root_dir, pattern), false, true)) do
      vim.fn.delete(path, "rf")
    end
  end
end

local function open_path(path)
  if vim.ui and vim.ui.open then
    vim.ui.open(path)
    return
  end

  local command
  if os.is_windows then
    command = { "cmd", "/c", "start", "", path }
  elseif os.is_macos then
    command = { "open", path }
  else
    command = { "xdg-open", path }
  end

  vim.fn.jobstart(command, { detach = true })
end

local function build_tex(root_file)
  if not root_file or vim.fn.filereadable(root_file) ~= 1 then
    return
  end

  local root_dir = vim.fn.fnamemodify(root_file, ":p:h")
  local root_name = vim.fn.fnamemodify(root_file, ":t")
  local key = vim.fn.fnamemodify(root_file, ":p")

  if running[key] then
    pending[key] = true
    return
  end

  local missing = missing_executables({ "latexmk", "uplatex", "upbibtex", "dvipdfmx" })
  if #missing > 0 then
    vim.notify("Missing TeX command(s) on PATH: " .. table.concat(missing, ", "), vim.log.levels.ERROR, {
      title = "LaTeX",
    })
    return
  end

  running[key] = true
  pending[key] = false

  local cmd = {
    "latexmk",
    "-e",
    "$latex=q/uplatex %O -kanji=utf8 -no-guess-input-enc -synctex=1 -interaction=nonstopmode -file-line-error %S/",
    "-e",
    "$bibtex=q/upbibtex %O %B/",
    "-e",
    "$biber=q/biber %O --bblencoding=utf8 -u -U --output_safechars %B/",
    "-e",
    "$makeindex=q/upmendex %O -o %D %S/",
    "-e",
    "$dvipdf=q/dvipdfmx %O -o %D %S/",
    "-norc",
    "-gg",
    "-pdfdvi",
    root_name,
  }

  notify("building " .. root_name)

  vim.system(cmd, {
    cwd = root_dir,
    text = true,
  }, function(result)
    running[key] = false

    local output = table.concat({
      result.stdout or "",
      result.stderr or "",
    }, "\n")

    if result.code == 0 then
      vim.schedule(function()
        clean_aux_files(root_file)
        vim.fn.setqflist({}, "r")
        vim.notify("updated " .. vim.fn.fnamemodify(root_file, ":r") .. ".pdf", vim.log.levels.INFO, {
          title = "LaTeX",
        })
      end)
    else
      vim.schedule(function()
        set_quickfix_from_output("LaTeX build: " .. root_name, output)
        vim.cmd("cwindow")
        vim.notify("build failed: " .. root_name, vim.log.levels.ERROR, {
          title = "LaTeX",
        })
      end)
    end

    if pending[key] then
      pending[key] = false
      vim.schedule(function()
        build_tex(root_file)
      end)
    end
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  group = edit_group,
  pattern = { "tex", "plaintex", "latex" },
  callback = function()
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = false
    vim.opt_local.cindent = false
    vim.opt_local.indentexpr = ""
    vim.opt_local.indentkeys = ""
    vim.opt_local.textwidth = 0
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.formatoptions:remove({ "t", "c", "r", "o" })
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = build_group,
  pattern = "*.tex",
  callback = function(args)
    local root_file = find_tex_root(args.buf)
    if root_file then
      build_tex(root_file)
    end
  end,
})

vim.api.nvim_create_user_command("TexBuild", function()
  local root_file = find_tex_root(0)
  if not root_file then
    vim.notify("TeX root file was not found", vim.log.levels.WARN, { title = "LaTeX" })
    return
  end
  build_tex(root_file)
end, { desc = "Build the current LaTeX project" })

vim.api.nvim_create_user_command("TexOpenPdf", function()
  local root_file = find_tex_root(0)
  if not root_file then
    vim.notify("TeX root file was not found", vim.log.levels.WARN, { title = "LaTeX" })
    return
  end

  local pdf = vim.fn.fnamemodify(root_file, ":r") .. ".pdf"
  if vim.fn.filereadable(pdf) ~= 1 then
    vim.notify("PDF not found: " .. pdf, vim.log.levels.WARN, { title = "LaTeX" })
    return
  end

  open_path(pdf)
end, { desc = "Open the current LaTeX project's PDF" })
