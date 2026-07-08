local M = {}

local default_config = {
  highlight = "ReadableTextBackground",
  pattern = "\\S",
  priority = 1,
  excluded_filetypes = {
    NvimTree = true,
    TelescopePrompt = true,
    TelescopeResults = true,
    TelescopePreview = true,
  },
}

local config = vim.deepcopy(default_config)

local function get_match_id(winid)
  local ok, match_id = pcall(vim.api.nvim_win_get_var, winid, "readable_text_background_match_id")
  if ok then
    return match_id
  end
  return nil
end

local function clear_match(winid)
  local match_id = get_match_id(winid)
  if not match_id then
    return
  end

  if vim.api.nvim_win_is_valid(winid) then
    pcall(vim.api.nvim_win_call, winid, function()
      vim.fn.matchdelete(match_id)
    end)
  end
  pcall(vim.api.nvim_win_del_var, winid, "readable_text_background_match_id")
end

local function is_normal_editing_window(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return false
  end

  if vim.api.nvim_win_get_config(winid).relative ~= "" then
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end

  return not config.excluded_filetypes[vim.bo[bufnr].filetype]
end

local function sync_window(winid)
  if not is_normal_editing_window(winid) then
    clear_match(winid)
    return
  end

  if get_match_id(winid) then
    return
  end

  local match_id = nil
  pcall(vim.api.nvim_win_call, winid, function()
    match_id = vim.fn.matchadd(config.highlight, config.pattern, config.priority)
  end)

  if type(match_id) == "number" and match_id > 0 then
    vim.api.nvim_win_set_var(winid, "readable_text_background_match_id", match_id)
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})

  local group = vim.api.nvim_create_augroup("ReadableTextBackground", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter", "FileType", "TermOpen" }, {
    group = group,
    callback = function()
      sync_window(vim.api.nvim_get_current_win())
    end,
  })

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    sync_window(winid)
  end
end

return M
