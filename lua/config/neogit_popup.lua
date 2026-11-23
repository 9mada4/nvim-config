-- Selection, execution (<CR>/<Space>) and Japanese explanations (?) for
-- Neogit popups. Neogit's own keys keep working; these only add bindings.
local M = {}
M.namespace = vim.api.nvim_create_namespace("nvim-config-neogit-popup")
local explain_win = {}

local function instance(buf)
  local popup = require("neogit.lib.popup").instance
  if popup and popup.buffer and popup.buffer.handle == buf then
    return popup
  end
end

-- Actions are laid out in a grid, so several can share one line. Pick the
-- label whose span (plus the gap after it) contains the cursor column.
local function action_on_line(popup, line, col)
  for _, group in ipairs(popup.state.actions) do
    for _, action in ipairs(group) do
      if action.callback and type(action.keys) == "table" and #action.keys > 0 then
        local label = table.concat(action.keys, ",") .. " " .. action.description
        local init = 1
        while true do
          local start = line:find(label, init, true)
          if not start then
            break
          end
          local before = start == 1 and " " or line:sub(start - 1, start - 1)
          local first, last = start - 1, start - 1 + #label + 2
          if before == " " and col >= first - 1 and col <= last then
            return {
              kind = "action",
              keys = action.keys[1],
              description = action.description,
              popup = popup.state.name,
              col = first,
              len = #label,
            }
          end
          init = start + 1
        end
      end
    end
  end
end

---@return table|nil item {kind, keys, description, popup, cli?, name?, col?, len?}
function M.item_under_cursor(buf)
  local popup = instance(buf)
  local win = vim.fn.bufwinid(buf)
  if not popup or win == -1 then
    return nil
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local component = popup.buffer.ui:get_interactive_component_under_cursor()
  if component then
    local tag, value = component.options.tag, component.options.value
    if tag == "Switch" or tag == "Option" then
      return {
        kind = tag:lower(),
        keys = value.id,
        description = value.description,
        cli = value.cli_prefix .. value.cli,
        popup = popup.state.name,
      }
    elseif tag == "Config" and not value.passive then
      return { kind = "config", keys = value.id, description = value.name, name = value.name, popup = popup.state.name }
    end
    return nil
  end
  local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1] or ""
  return action_on_line(popup, line, cursor[2])
end

function M.close_explanation(buf)
  local win = explain_win[buf]
  explain_win[buf] = nil
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    return true
  end
  return false
end

function M.run(buf)
  local item = M.item_under_cursor(buf)
  if not item then
    return
  end
  M.close_explanation(buf)
  -- Call Neogit's own buffer mapping for the key, so behaviour is identical
  -- to pressing it. Fall back to typeahead if it is not a Lua mapping.
  local wanted = vim.keycode(item.keys)
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if mapping.callback and vim.keycode(mapping.lhs) == wanted then
      return mapping.callback()
    end
  end
  vim.api.nvim_feedkeys(wanted, "m", false)
end

function M.explain(buf)
  local item = M.item_under_cursor(buf)
  if not item then
    return
  end
  M.close_explanation(buf)
  local entry = require("config.neogit_help_ja").lookup(item)
  local lines = { entry.title, "" }
  vim.list_extend(lines, entry.body)
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 2, math.floor(vim.o.columns * 0.8))
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.api.nvim_buf_add_highlight(float_buf, M.namespace, "Title", 0, 0, -1)
  -- The popup closes on WinLeave, so the float must never take focus.
  explain_win[buf] = vim.api.nvim_open_win(float_buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(#lines, math.max(vim.o.lines - 4, 1)),
    style = "minimal",
    border = "rounded",
    title = " 説明 (q で閉じる) ",
    focusable = false,
    zindex = 60,
  })
  vim.wo[explain_win[buf]].wrap = true
end

local function highlight(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
  local item = M.item_under_cursor(buf)
  if not item then
    return
  end
  local row = vim.api.nvim_win_get_cursor(vim.fn.bufwinid(buf))[1] - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local col = item.col or 0
  local end_col = item.len and math.min(col + item.len, #line) or #line
  vim.api.nvim_buf_set_extmark(buf, M.namespace, row, col, { end_col = end_col, hl_group = "Visual" })
end

local function attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].nvim_config_popup_attached then
    return
  end
  vim.b[buf].nvim_config_popup_attached = true
  local opts = { buffer = buf, nowait = true, silent = true }
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, vim.tbl_extend("force", opts, { desc = desc }))
  end
  map("<CR>", function() M.run(buf) end, "選択中の操作を実行")
  map("<Space>", function() M.run(buf) end, "選択中の操作を実行")
  map("?", function() M.explain(buf) end, "選択中の操作の説明")
  -- q/<Esc> close the explanation first; with none open they close the popup
  -- exactly like Neogit's own mapping.
  for _, lhs in ipairs({ "q", "<Esc>" }) do
    map(lhs, function()
      if not M.close_explanation(buf) then
        local popup = instance(buf)
        if popup then
          popup:close()
        end
      end
    end, "説明 / ポップアップを閉じる")
  end
  local group = vim.api.nvim_create_augroup("NvimConfigNeogitPopup" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function()
      M.close_explanation(buf)
      highlight(buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufHidden", "BufWipeout" }, {
    group = group,
    buffer = buf,
    callback = function()
      M.close_explanation(buf)
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
  highlight(buf)
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NvimConfigNeogitPopupSetup", { clear = true }),
    pattern = "NeogitPopup*",
    callback = function(args)
      -- Neogit installs its own buffer maps after FileType; ours go last.
      vim.schedule(function()
        attach(args.buf)
      end)
    end,
  })
end

return M
