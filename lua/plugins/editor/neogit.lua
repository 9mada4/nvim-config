local generated_commits = {}

local function commit_with_generated_message()
  local cwd = vim.fn.getcwd()
  local repo = require("neogit.lib.git.repository").instance(cwd)
  local edit_path = vim.fs.normalize(vim.fs.joinpath(repo.worktree_git_dir, "COMMIT_EDITMSG"))
  if generated_commits[edit_path] then
    return
  end

  local commit_message = require("config.commit_message")
  local result = commit_message.generate("rule", repo.worktree_root):wait()
  local message = vim.trim(result.stdout or "")
  if result.code ~= 0 or result.signal ~= 0 or message == "" then
    local detail = (result.stderr or ""):match("[^\r\n]+")
    vim.notify("コミットメッセージを生成できませんでした" .. (detail and ": " .. detail or ""), vim.log.levels.WARN)
    return
  end
  if message == "変更がありません" then
    vim.notify(message, vim.log.levels.INFO)
    return
  end

  local autocmd = vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function(args)
      if vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf)) ~= edit_path then
        return
      end

      -- Wait for Neogit to open the editor window and position the cursor.
      vim.schedule(function()
        if vim.api.nvim_buf_is_loaded(args.buf) then
          commit_message.start(args.buf, repo.worktree_root)
        end
      end)
      return true
    end,
  })
  generated_commits[edit_path] = true

  local git = require("neogit.lib.git")
  local client = require("neogit.client")
  local async = require("neogit.lib.async")
  local config = require("neogit.config").values
  repo:dispatch_refresh {
    source = "generated_commit",
    callback = function()
      local task = async.run(function()
        require("neogit.lib.git.repository").instance(cwd)
        client.wrap(git.cli.commit.edit.message(message), {
          autocmd = "NeogitCommitComplete",
          msg = { success = "Committed", fail = "Commit failed" },
          interactive = true,
          show_diff = config.commit_editor.show_staged_diff,
        })
      end)
      task:on_complete(function()
        generated_commits[edit_path] = nil
        pcall(vim.api.nvim_del_autocmd, autocmd)
      end)
    end,
  }
end

local function pull_with_rebase()
  local cwd = vim.fn.getcwd()
  local async = require("neogit.lib.async")
  async.run(function()
    require("neogit.lib.git.repository").instance(cwd)
    local git = require("neogit.lib.git")
    local notification = require("neogit.lib.notification")
    notification.info("Running git pull --rebase")
    local result = git.pull.pull_interactive(nil, nil, { "--rebase" })
    if result:success() then
      notification.info("Pulled with rebase", { dismiss = true })
      require("neogit.lib.event").send("PullComplete")
    else
      notification.error("git pull --rebase failed", { dismiss = true })
    end
  end)
end

return {
  "NeogitOrg/neogit",
  cmd = "Neogit",
  keys = {
    { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    mappings = {
      status = {
        R = pull_with_rebase,
        G = commit_with_generated_message,
      },
    },
  },
}
