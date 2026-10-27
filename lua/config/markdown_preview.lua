local M = {}

local node_server_started = false

function M.run(action)
  local ok, error_message = pcall(function()
    require("lazy").load({ plugins = { "markdown-preview.nvim" } })

    local starting = action == "start" or (action == "toggle" and not vim.b.MarkdownPreviewToggleBool)
    if not starting then
      if action == "stop" then
        vim.fn["mkdp#util#stop_preview"]()
      else
        vim.fn["mkdp#util#toggle_preview"]()
      end
      node_server_started = false
      return
    end

    if vim.fn.executable("node") ~= 1 then
      error("markdown-preview.nvim needs Node.js for reload support")
    end

    -- An already running native server cannot load NODE_OPTIONS. Replace it
    -- when this configuration is first used in an existing Neovim session.
    if not node_server_started and vim.fn["mkdp#rpc#get_server_status"]() == 1 then
      local has_channel = vim.wait(3000, function()
        return type(vim.g.mkdp_node_channel_id) == "number"
      end, 50)
      if not has_channel or vim.fn.jobstop(vim.g.mkdp_node_channel_id) ~= 1 then
        error("could not stop the existing markdown-preview server")
      end
      if not vim.wait(3000, function()
        return vim.fn["mkdp#rpc#get_server_status"]() == -1
      end, 50) then
        error("existing markdown-preview server did not stop")
      end
    end

    local plugin = require("lazy.core.config").plugins["markdown-preview.nvim"]
    local platform = vim.fn["mkdp#util#get_platform"]()
    local binary = plugin.dir .. "/app/bin/markdown-preview-" .. platform
    if platform == "win" then
      binary = binary .. ".exe"
    end

    local previous_node_options = vim.env.NODE_OPTIONS
    local previous_reload_fix = vim.env.MKDP_RELOAD_FIX
    local previous_mermaid_asset = vim.env.MKDP_MERMAID_ASSET
    local permissions = vim.fn.getfperm(binary)
    local masked = permissions ~= "" and permissions:gsub("x", "-") or nil
    local preload = vim.fn.stdpath("config") .. "/scripts/markdown-preview-reload-fix.cjs"
    local require_option = "--require=" .. preload

    -- The plugin prefers its bundled executable. Make it temporarily
    -- non-executable so its synchronous start_server() selects Node.js.
    if masked and masked ~= permissions and vim.fn.setfperm(binary, masked) ~= 1 then
      error("could not select the Node.js markdown-preview server")
    end

    vim.env.NODE_OPTIONS = previous_node_options and previous_node_options ~= ""
        and (previous_node_options .. " " .. require_option)
      or require_option
    vim.env.MKDP_RELOAD_FIX = "1"
    vim.env.MKDP_MERMAID_ASSET = vim.fn.stdpath("data") .. "/markdown-preview/mermaid.min.js"

    local command = action == "start" and "mkdp#util#open_preview_page" or "mkdp#util#toggle_preview"
    local command_ok, command_error = pcall(vim.fn[command])

    vim.env.NODE_OPTIONS = previous_node_options
    vim.env.MKDP_RELOAD_FIX = previous_reload_fix
    vim.env.MKDP_MERMAID_ASSET = previous_mermaid_asset
    if masked and masked ~= permissions then
      if vim.fn.setfperm(binary, permissions) ~= 1 then
        error("could not restore markdown-preview executable permissions")
      end
    end

    if not command_ok then
      error(command_error)
    end
    node_server_started = true
  end)

  return ok, error_message
end

function M.toggle()
  return M.run("toggle")
end

function M.setup_commands()
  local function install(buffer)
    if vim.bo[buffer].filetype ~= "markdown" then
      return
    end
    for name, action in pairs({
      MarkdownPreview = "start",
      MarkdownPreviewStop = "stop",
      MarkdownPreviewToggle = "toggle",
    }) do
      vim.api.nvim_buf_create_user_command(buffer, name, function()
        local ok, error_message = M.run(action)
        if not ok then
          vim.notify("Markdown preview: " .. tostring(error_message), vim.log.levels.ERROR)
        end
      end, { force = true })
    end
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    callback = function(event)
      install(event.buf)
    end,
  })
  install(vim.api.nvim_get_current_buf())
end

return M
