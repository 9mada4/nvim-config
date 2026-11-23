local M = {}
local active_commits = {}
local hint_namespace = vim.api.nvim_create_namespace("nvim-config-neogit-hints")

-- Popup actions already run in Neogit's async context. Reject index changes
-- during generation, and always ask Git to open Neogit's normal editor (-e).
function M.commit(mode)
  local async = require("neogit.lib.async")
  local repository = require("neogit.lib.git.repository")
  local repo = repository.instance(vim.fn.getcwd())
  local root = repo.worktree_root
  local edit_path = vim.fs.normalize(vim.fs.joinpath(repo.worktree_git_dir, "COMMIT_EDITMSG"))
  if active_commits[edit_path] then
    vim.notify("コミットメッセージを生成・編集中です", vim.log.levels.INFO)
    return
  end
  active_commits[edit_path] = true

  local cleanup
  local ok, err = pcall(function()
    local system = async.wrap(function(argv, callback)
      vim.system(argv, { cwd = root, text = true }, vim.schedule_wrap(callback))
    end, 2)
    local function index_tree()
      local result = system({ "git", "write-tree" })
      if result.code ~= 0 or result.signal ~= 0 then
        error("ステージ済みの変更を読み込めませんでした: " .. (result.stderr or ""))
      end
      return result.stdout
    end
    local tree = index_tree()
    local commit_message = require("config.commit_message")
    local message, supplement = async.wrap(commit_message.prepare, 3)(mode, root)
    if not message then
      return
    end
    repository.instance(root)
    async.wrap(function(callback)
      repo:dispatch_refresh { source = "generated_commit", callback = callback }
    end, 1)()
    if index_tree() ~= tree then
      vim.notify("生成中にステージ内容が変わりました。もう一度生成してください", vim.log.levels.WARN)
      return
    end
    cleanup = commit_message.generated_editor(edit_path, supplement)
    repository.instance(root)
    -- Deliberately omit popup flags (especially --all and --reuse-message).
    require("neogit.client").wrap(require("neogit.lib.git").cli.commit.edit.message(message), {
      autocmd = "NeogitCommitComplete",
      msg = { success = "Committed", fail = "Commit failed" },
      interactive = true,
      show_diff = require("neogit.config").values.commit_editor.show_staged_diff,
    })
  end)
  if cleanup then
    cleanup()
  end
  active_commits[edit_path] = nil
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

-- Neogit exposes disable_hint, but no builder for the status hint. Virtual
-- lines use only Neovim APIs and leave Neogit's buffer rows/selection intact.
function M.update_hints(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "NeogitStatus" then
    return
  end
  local mappings = require("neogit.config").values.mappings
  local function entry(set, action, label)
    local keys = {}
    for key, value in pairs(mappings[set]) do
      local override = set == "popup" and mappings.status[key]
      if value == action and not override then
        keys[#keys + 1] = key:gsub("<[Tt][Aa][Bb]>", "Tab")
      end
    end
    table.sort(keys)
    return {
      { keys[1] or "<unmapped>", "NeogitPopupActionKey" },
      { " " .. label, "NeogitSubtleText" },
    }
  end
  local function line(entries)
    local chunks = {}
    for i, spec in ipairs(entries) do
      if i > 1 then
        chunks[#chunks + 1] = { " | ", "NeogitSubtleText" }
      end
      vim.list_extend(chunks, entry(unpack(spec)))
    end
    return chunks
  end
  local lines = {
    line({
      { "status", "Toggle", "Diff" },
      { "status", "Stage", "Stage" },
      { "status", "Unstage", "Unstage" },
      { "popup", "CommitPopup", "Commit" },
      { "status", "Discard", "Discard" },
    }),
    line({
      { "popup", "PullPopup", "Pull" },
      { "popup", "PushPopup", "Push" },
      { "popup", "StashPopup", "Stash" },
      { "popup", "HelpPopup", "Help" },
      { "status", "Close", "Close" },
    }),
  }
  vim.api.nvim_buf_set_extmark(buf, hint_namespace, 0, 0, {
    id = 1,
    right_gravity = false,
    virt_lines = lines,
    virt_lines_above = true,
  })
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      local view = vim.fn.winsaveview()
      if view.topline == 1 then
        view.topfill = #lines
        vim.fn.winrestview(view)
      end
    end)
  end
end

function M.setup_hints()
  local group = vim.api.nvim_create_augroup("NvimConfigNeogitHints", { clear = true })
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype == "NeogitStatus" then
        vim.schedule(function()
          M.update_hints(args.buf)
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "NeogitStatusRefreshed",
    callback = function()
      vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          M.update_hints(buf)
        end
      end)
    end,
  })
end

return M
