return {
  "StefanBartl/reposcope.nvim",
  name = "reposcope",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local gh = require("reposcope.network.request_tools.gh")
    local reposcope_config = require("reposcope.config")
    local provider_controller = require("reposcope.controllers.provider_controller")
    local request_state = require("reposcope.state.requests_state")
    local repo_cache = require("reposcope.cache.repository_cache")
    local core = require("reposcope.utils.core")
    local readme_manager = require("reposcope.providers.github.readme.readme_manager")
    local get_clone_informations = require("reposcope.providers.github.clone.clone_info").get_clone_informations
    local reposcope_init = require("reposcope.init")
    local ui_state = require("reposcope.state.ui.ui_state")
    local list_window = require("reposcope.ui.list.list_window")
    local list_manager = require("reposcope.ui.list.list_manager")
    local display_repositories = require("reposcope.controllers.list_controller").display_repositories
    local ui_loader = require("reposcope.providers.github.repositories.repository_ui_loader")

    local clone_terminal = (function()
      local M = {}
      local state = {
        buf = nil,
        win = nil,
        chan = nil,
        timer = nil,
      }

      local function is_valid_buf(buf)
        return type(buf) == "number" and vim.api.nvim_buf_is_valid(buf)
      end

      local function is_valid_win(win)
        return type(win) == "number" and vim.api.nvim_win_is_valid(win)
      end

      local function stop_timer()
        if state.timer then
          state.timer:stop()
          state.timer:close()
          state.timer = nil
        end
      end

      local function float_config()
        local width = math.max(80, math.floor(vim.o.columns * 0.78))
        width = math.min(width, math.max(80, vim.o.columns - 4))
        local height = math.max(12, math.floor(vim.o.lines * 0.38))
        height = math.min(height, math.max(12, vim.o.lines - 4))
        local row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1)
        local col = math.max(1, math.floor((vim.o.columns - width) / 2))

        return {
          relative = "editor",
          row = row,
          col = col,
          width = width,
          height = height,
          style = "minimal",
          border = "rounded",
          focusable = true,
          noautocmd = true,
          zindex = 320,
        }
      end

      local function ensure_term_window()
        if not is_valid_buf(state.buf) then
          state.buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_name(state.buf, "reposcope://clone-terminal")
          vim.bo[state.buf].bufhidden = "wipe"
          vim.bo[state.buf].swapfile = false
        end

        if not is_valid_win(state.win) then
          state.win = vim.api.nvim_open_win(state.buf, true, float_config())
        else
          vim.api.nvim_win_set_config(state.win, float_config())
        end

        vim.api.nvim_set_hl(0, "ReposcopeCloneTerm", { bg = "#1b2133", fg = "#c7d2fe" })
        vim.api.nvim_set_hl(0, "ReposcopeCloneTermBorder", { fg = "#7aa2f7", bg = "#1b2133" })
        vim.wo[state.win].winhighlight = "Normal:ReposcopeCloneTerm,FloatBorder:ReposcopeCloneTermBorder"
        vim.wo[state.win].number = false
        vim.wo[state.win].relativenumber = false
        vim.wo[state.win].cursorline = false
        vim.wo[state.win].signcolumn = "no"
        pcall(vim.api.nvim_set_current_win, state.win)
      end

      local function schedule_close(timeout)
        stop_timer()
        state.timer = vim.uv.new_timer()
        state.timer:start(timeout, 0, vim.schedule_wrap(function()
          M.close()
        end))
      end

      function M.close()
        stop_timer()

        if is_valid_win(state.win) then
          pcall(vim.api.nvim_win_close, state.win, true)
        end

        state.buf = nil
        state.win = nil
        state.chan = nil
      end

      function M.run(args, on_exit)
        if type(args) ~= "table" or #args == 0 then
          return false
        end

        M.close()
        ensure_term_window()

        if is_valid_buf(state.buf) then
          vim.bo[state.buf].modifiable = true
          vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})
          vim.bo[state.buf].modifiable = false
        end

        local chan = nil
        vim.api.nvim_buf_call(state.buf, function()
          chan = vim.fn.termopen(args, {
            on_exit = function(_, code, _)
              vim.schedule(function()
                if type(on_exit) == "function" then
                  pcall(on_exit, code)
                end

                if code == 0 then
                  schedule_close(1000)
                else
                  schedule_close(4000)
                end
              end)
            end,
          })
        end)

        if not chan or chan <= 0 then
          M.close()
          return false
        end

        state.chan = chan
        vim.schedule(function()
          if is_valid_win(state.win) then
            pcall(vim.api.nvim_set_current_win, state.win)
            pcall(vim.cmd, "startinsert")
          end
        end)
        return true
      end

      return M
    end)()

    local function build_env(token)
      local env_map = vim.fn.environ()
      if token and token ~= "" then
        env_map.GITHUB_TOKEN = token
      end

      local env = {}
      for key, value in pairs(env_map) do
        env[#env + 1] = key .. "=" .. value
      end
      return env
    end

    gh.request = function(method, url, callback, headers, debug, context, uuid)
      local start_time = vim.uv.hrtime()
      local stdout = vim.uv.new_pipe(false)
      local stderr = vim.uv.new_pipe(false)
      local safe_uuid = uuid or "n/a"
      local safe_context = context or "unspecified"
      local response_data = {}
      local stderr_data = {}

      local token = reposcope_config.options.github_token
      local parsed = url:gsub("^https://api%.github%.com", "")
      local args = { "api", parsed, "--method", method }

      for k, v in pairs(headers or {}) do
        args[#args + 1] = "--header"
        args[#args + 1] = k .. ": " .. v
      end

      if debug then
        table.insert(args, "--verbose")
      end

      local handle = vim.uv.spawn("gh", {
        args = args,
        stdio = { nil, stdout, stderr },
        env = build_env(token),
      }, vim.schedule_wrap(function(code)
        if stdout then stdout:close() end
        if stderr then stderr:close() end

        local duration = (vim.uv.hrtime() - start_time) / 1e6
        local metrics = require("reposcope.utils.metrics")
        local notify = require("reposcope.utils.debug").notify

        if code ~= 0 then
          if metrics.record_metrics() then
            metrics.increase_failed(safe_uuid, url, "gh", safe_context, duration, code, "gh CLI error")
          end
          notify("[reposcope] gh exited with code " .. code, 4)
          notify("[reposcope] stderr: " .. table.concat(stderr_data, ""), 2)
          callback(nil, "gh request failed (code " .. code .. ")")
        else
          local result = table.concat(response_data)
          if metrics.record_metrics() then
            metrics.increase_success(safe_uuid, url, "gh", safe_context, duration, 200)
          end
          callback(result)
        end
      end))

      if not handle then
        callback(nil, "Failed to spawn gh CLI")
        return
      end

      if stdout then
        stdout:read_start(function(err, data)
          if err then
            callback(nil, "gh stdout error: " .. err)
            return
          end
          if data then
            table.insert(response_data, data)
          end
        end)
      end

      if stderr then
        stderr:read_start(function(err, data)
          if err then
            require("reposcope.utils.debug").notify("[reposcope] gh stderr read error: " .. err, 5)
            return
          end
          if data then
            table.insert(stderr_data, data)
            if debug then
              require("reposcope.utils.debug").notify("[reposcope] gh stderr: " .. data, 4)
            end
          end
        end)
      end
    end

    local function normalize_path(path)
      return vim.fs.normalize(vim.fn.expand(path))
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

    local function spawn_clone_in_terminal(args, repo_name, uuid)
      local ok = clone_terminal.run(args, function(code)
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

    reposcope_init.setup({})

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
      clone_terminal.close()
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

    ui_loader.load_ui_after_fetch = function()
      vim.schedule(function()
        local selected_line = list_window.highlighted_line or ui_state.list.last_selected_line or 1
        ui_state.list.last_selected_line = selected_line
        list_manager.reset_selected_line()
        display_repositories()
        fetch_selected_readme_with_retry()
      end)
    end

    provider_controller.prompt_and_clone = function()
      local cwd = vim.fn.getcwd()
      local infos = get_clone_informations()

      if not infos then
        return
      end

      local repo_name = infos.name
      local repo_url = infos.url
      local target_root = normalize_path(cwd)

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

      local clone_type = reposcope_config.options.clone.type
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

      vim.schedule(function()
        local ok, err = pcall(reposcope_init.close_ui)
        if not ok then
          request_state.end_request(uuid)
          vim.notify(
            string.format("[reposcope] Failed to close UI before clone: %s", tostring(err)),
            vim.log.levels.ERROR
          )
          return
        end

        vim.defer_fn(function()
          spawn_clone_in_terminal(args, repo_name, uuid)
        end, 10)
      end)
    end

    vim.keymap.set("n", "<leader>rs", "<cmd>ReposcopeStart<CR>", {
      desc = "Reposcope: search repositories",
    })
  end,
}
