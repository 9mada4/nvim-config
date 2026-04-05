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
  local debug = require("reposcope.utils.debug")
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

  local original_open_ui = reposcope_init.open_ui
  reposcope_init.open_ui = function(...)
    local result = original_open_ui(...)
    status.open()
    return result
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
      status.clear_search()
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

  local original_update_preview = require("reposcope.ui.preview.preview_manager").update_preview
  require("reposcope.ui.preview.preview_manager").update_preview = function(owner, repo_name)
    status.clear_search()
    return original_update_preview(owner, repo_name)
  end

  local original_fetch_repositories_and_display = provider_controller.fetch_repositories_and_display
  provider_controller.fetch_repositories_and_display = function(query)
    status.set_search("Search: " .. query)
    return original_fetch_repositories_and_display(query)
  end

  local function normalize_path(path)
    return vim.fs.normalize(vim.fn.expand(path))
  end

  local function update_clone_status(repo_name, message)
    status.set_clone(string.format("Clone %s: %s", repo_name, message))
  end

  local function parse_git_progress(data)
    if not data or data == "" then
      return nil
    end

    local cleaned = data:gsub("\r", "\n")
    local last
    for line in cleaned:gmatch("[^\n]+") do
      local phase, percent = line:match("(Counting objects):%s+(%d+%%)")
      if not phase then
        phase, percent = line:match("(Compressing objects):%s+(%d+%%)")
      end
      if not phase then
        phase, percent = line:match("(Receiving objects):%s+(%d+%%)")
      end
      if not phase then
        phase, percent = line:match("(Resolving deltas):%s+(%d+%%)")
      end
      if phase and percent then
        last = phase .. " " .. percent
      elseif line:match("^Cloning into") then
        last = line
      end
    end
    return last
  end

  local function spawn_clone(args, repo_name, uuid)
    local stdout = vim.uv.new_pipe(false)
    local stderr = vim.uv.new_pipe(false)
    local stderr_chunks = {}

    update_clone_status(repo_name, "starting")

    local handle
    handle = vim.uv.spawn(args[1], {
      args = vim.list_slice(args, 2),
      stdio = { nil, stdout, stderr },
    }, vim.schedule_wrap(function(code)
      if stdout then
        stdout:close()
      end
      if stderr then
        stderr:close()
      end
      if handle then
        handle:close()
      end

      request_state.end_request(uuid)

      if code == 0 then
        update_clone_status(repo_name, "done")
        vim.defer_fn(function()
          status.clear_clone()
        end, 2000)
        return
      end

      local err = table.concat(stderr_chunks):gsub("%s+$", "")
      if err == "" then
        err = "failed"
      end
      update_clone_status(repo_name, err)
      debug.notify("[reposcope] Clone failed: " .. err, vim.log.levels.ERROR)
    end))

    if not handle then
      request_state.end_request(uuid)
      update_clone_status(repo_name, "failed to start")
      debug.notify("[reposcope] Failed to spawn clone command", vim.log.levels.ERROR)
      return
    end

    local function on_progress(err, data)
      if err then
        return
      end
      local progress = parse_git_progress(data)
      if progress then
        update_clone_status(repo_name, progress)
      end
    end

    if stdout then
      stdout:read_start(on_progress)
    end

    if stderr then
      stderr:read_start(function(err, data)
        if err then
          return
        end
        if data then
          stderr_chunks[#stderr_chunks + 1] = data
        end
        on_progress(nil, data)
      end)
    end
  end

  provider_controller.prompt_and_clone = function()
    local cwd = vim.fn.getcwd()

    vim.ui.input({
      prompt = "Set clone path: ",
      default = cwd,
      completion = "file",
    }, function(input)
      if input == nil then
        debug.notify("[reposcope] Cloning canceled.", 2)
        return
      end

      local target_root = vim.trim(input)
      if target_root == "" then
        target_root = cwd
      end
      target_root = normalize_path(target_root)

      if vim.fn.isdirectory(target_root) ~= 1 then
        debug.notify("[reposcope] Clone request: Invalid path", vim.log.levels.ERROR)
        return
      end

      local infos = get_clone_informations()
      if not infos then
        return
      end

      local uuid = core.generate_uuid()
      request_state.register_request(uuid)
      request_state.start_request(uuid)

      local repo_name = infos.name
      local repo_url = infos.url
      local clone_type = config.options.clone.type
      local output_dir = normalize_path(target_root .. "/" .. repo_name)

      local args
      if clone_type == "gh" then
        args = { "gh", "repo", "clone", repo_url, output_dir, "--", "--progress" }
      elseif clone_type == "curl" then
        args = { "curl", "-L", "-#","-o", output_dir .. ".zip", repo_url:gsub("%.git$", "/archive/refs/heads/main.zip") }
      elseif clone_type == "wget" then
        args = { "wget", "--show-progress", "-O", output_dir .. ".zip", repo_url:gsub("%.git$", "/archive/refs/heads/main.zip") }
      else
        args = { "git", "clone", "--progress", repo_url, output_dir }
      end

      spawn_clone(args, repo_name, uuid)
    end)
  end
end

return M
