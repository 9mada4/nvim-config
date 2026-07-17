local M = {}

function M.toggle()
  local previous_node_options = vim.env.NODE_OPTIONS
  local previous_reload_fix = vim.env.MKDP_RELOAD_FIX
  local preload = vim.fn.stdpath("config") .. "/scripts/markdown-preview-reload-fix.cjs"
  local require_option = "--require=" .. preload

  -- Limit the HTTP redirect shim to the preview process spawned by this command.
  vim.env.NODE_OPTIONS = previous_node_options and previous_node_options ~= ""
      and (previous_node_options .. " " .. require_option)
    or require_option
  vim.env.MKDP_RELOAD_FIX = "1"

  local ok, error_message = pcall(vim.cmd, "MarkdownPreviewToggle")

  vim.env.NODE_OPTIONS = previous_node_options
  vim.env.MKDP_RELOAD_FIX = previous_reload_fix

  return ok, error_message
end

return M
