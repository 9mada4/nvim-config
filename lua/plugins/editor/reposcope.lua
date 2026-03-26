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
    local config = require("reposcope.config")

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

      local token = config.options.github_token
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

    require("reposcope.init").setup({})

    vim.keymap.set("n", "<leader>rs", "<cmd>ReposcopeStart<CR>", {
      desc = "Reposcope: search repositories",
    })
  end,
}
