local function get_chappy_screenshot_path()
  local path = vim.env.CHAPPY_SCREENSHOT_PATH
  if not path or path == "" then
    path = (vim.env.HOME or "~") .. "/Pictures/Screenshot/screenshotToText.png"
  end
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

local function send_chappy_screenshot_to_codex()
  local path = get_chappy_screenshot_path()
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("Screenshot file not found: " .. path, vim.log.levels.WARN)
    return
  end

  local ok, terminal = pcall(require, "codex.terminal")
  if not ok or type(terminal.send) ~= "function" then
    vim.notify("Codex terminal is not ready", vim.log.levels.WARN)
    return
  end

  local prompt = "@" .. path .. " この画像を見て"
  if not terminal.send(prompt) then
    vim.notify("Could not send screenshot path to Codex: " .. path, vim.log.levels.WARN)
  end
end

return {
  {
    "ishiooon/codex.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    cmd = {
      "Codex",
      "CodexFocus",
      "CodexSend",
      "CodexTreeAdd",
    },
    keys = {
      { "<leader>cc", "<cmd>Codex<CR>", desc = "Codex: Toggle" },
      { "<leader>cf", "<cmd>CodexFocus<CR>", desc = "Codex: Focus" },
      { "<leader>ci", send_chappy_screenshot_to_codex, desc = "Codex: Send screenshot image" },
      { "<leader>cs", "<cmd>CodexSend<CR>", mode = "v", desc = "Codex: Send selection" },
    },
    opts = function()
      local cmd = vim.fn.exepath("codex")
      if cmd == "" and vim.fn.filereadable("/Applications/Codex.app/Contents/Resources/codex") == 1 then
        cmd = "/Applications/Codex.app/Contents/Resources/codex"
      end
      if cmd == "" then
        cmd = nil
      end

      return {
        terminal_cmd = cmd,
        terminal = {
          provider = "snacks",
          snacks_win_opts = {
            position = "bottom",
            height = 0.5,
          },
        },
        status_indicator = {
          enabled = false,
        },
      }
    end,
  },
}
