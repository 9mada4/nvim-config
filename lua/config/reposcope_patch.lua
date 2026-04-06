local M = {}

function M.setup()
  local status = require("config.reposcope_status")
  local reposcope_init = require("reposcope.init")
  local ui_state = require("reposcope.state.ui.ui_state")
  local list_window = require("reposcope.ui.list.list_window")
  local list_manager = require("reposcope.ui.list.list_manager")
  local display_repositories = require("reposcope.controllers.list_controller").display_repositories
  local provider_controller = require("reposcope.controllers.provider_controller")
  local request_state = require("reposcope.state.requests_state")
  local repo_cache = require("reposcope.cache.repository_cache")
  local readme_manager = require("reposcope.providers.github.readme.readme_manager")
  local core = require("reposcope.utils.core")
  local config = require("reposcope.config")
  local get_clone_informations = require("reposcope.providers.github.clone.clone_info").get_clone_informations

  repo_cache.get_selected = function()
    local data = repo_cache.get()
    local items = data and data.items
    if type(items) ~= "table" or #items == 0 then
      return nil
    end

    local selected = list_window.highlighted_line or 1
    local list_buf = ui_state.buffers.list
    if type(list_buf) ~= "number" or not vim.api.nvim_buf_is_valid(list_buf) then
      return nil
    end

    local line_count = vim.api.nvim_buf_line_count(list_buf)
    if line_count == 0 then
      return nil
    end
    if selected > line_count then
      selected = 1
    end

    local line = vim.api.nvim_buf_get_lines(list_buf, selected - 1, selected, false)[1]
    if type(line) ~= "string" or line == "" then
      return nil
    end

    local owner, repo_name = line:match("([^/]+)/([^:]+)")
    if not owner or not repo_name then
      return nil
    end

    for i = 1, #items do
      local repo = items[i]
      if repo.name == repo_name and repo.owner and repo.owner.login == owner then
        return repo
      end
    end

    return nil
  end

  local original_close_ui = reposcope_init.close_ui
  reposcope_init.close_ui = function(...)
    status.close()
    return original_close_ui(...)
  end

  local original_open_window = list_window.open_window
  list_window.open_window = function()
    if ui_state.buffers.list and not vim.api.nvim_buf_is_valid(ui_state.buffers.list) then
      ui_state.buffers.list = nil
    end
    if ui_state.windows.list and not vim.api.nvim_win_is_valid(ui_state.windows.list) then
      ui_state.windows.list = nil
    end
    if ui_state.buffers.list and not ui_state.windows.list then
      ui_state.buffers.list = nil
    end
    return original_open_window()
  end

  local function fetch_selected_readme_with_retry(attempt)
    attempt = attempt or 1
    local selected = repo_cache.get_selected()
    if selected and selected.owner and selected.owner.login and selected.name then
      local uuid = core.generate_uuid()
      request_state.register_request(uuid)
      readme_manager.fetch_for_selected(uuid)
      return
    end

    if attempt >= 8 then
      return
    end

    vim.defer_fn(function()
      fetch_selected_readme_with_retry(attempt + 1)
    end, 80)
  end

  local ui_loader = require("reposcope.providers.github.repositories.repository_ui_loader")
  ui_loader.load_ui_after_fetch = function()
    vim.schedule(function()
      local selected_line = list_window.highlighted_line or 1
      ui_state.list.last_selected_line = selected_line
      reposcope_init.close_ui()
      reposcope_init.open_ui()
      list_manager.reset_selected_line()
      display_repositories()
      fetch_selected_readme_with_retry()
    end)
  end

  local function normalize_path(path)
    return vim.fs.normalize(vim.fn.expand(path))
  end

  local function spawn_clone_in_terminal(args, repo_name, uuid)
    local ok = status.run_clone_terminal(args, function(code)
      request_state.end_request(uuid)

      if code ~= 0 then
        vim.notify(
          string.format("[reposcope] Clone failed for %s (exit %d)", repo_name, code),
          vim.log.levels.ERROR
        )
      end
    end)

    if not ok then
      request_state.end_request(uuid)
      vim.notify("[reposcope] Failed to open clone terminal window", vim.log.levels.ERROR)
    end
  end

  provider_controller.prompt_and_clone = function()
    local cwd = vim.fn.getcwd()
    local infos = get_clone_informations()

    if not infos then
      return
    end

    local repo_name = infos.name
    local repo_url = infos.url

    vim.ui.input({
      prompt = "Set clone path: ",
      default = cwd,
      completion = "file",
    }, function(input)
      if input == nil then
        return
      end

      local target_root = vim.trim(input)
      if target_root == "" then
        target_root = cwd
      end
      target_root = normalize_path(target_root)

      if vim.fn.isdirectory(target_root) ~= 1 then
        vim.notify(
          string.format("[reposcope] Clone path does not exist: %s", target_root),
          vim.log.levels.ERROR
        )
        return
      end

      local uuid = core.generate_uuid()
      request_state.register_request(uuid)
      request_state.start_request(uuid)

      local clone_type = config.options.clone.type
      local output_dir = normalize_path(target_root .. "/" .. repo_name)

      local args
      if clone_type == "gh" then
        args = { "gh", "repo", "clone", repo_url, output_dir, "--", "--progress" }
      elseif clone_type == "curl" then
        args = {
          "curl",
          "-L",
          "-#",
          "-o",
          output_dir .. ".zip",
          repo_url:gsub("%.git$", "/archive/refs/heads/main.zip"),
        }
      elseif clone_type == "wget" then
        args = {
          "wget",
          "--show-progress",
          "-O",
          output_dir .. ".zip",
          repo_url:gsub("%.git$", "/archive/refs/heads/main.zip"),
        }
      else
        args = { "git", "clone", "--progress", repo_url, output_dir }
      end

      reposcope_init.close_ui()
      vim.schedule(function()
        spawn_clone_in_terminal(args, repo_name, uuid)
      end)
    end)
  end
end

return M
