local function clear_match()
  local match_id = vim.w.cursor_word_match_id
  if match_id then
    pcall(vim.fn.matchdelete, match_id)
    vim.w.cursor_word_match_id = nil
  end
  vim.w.cursor_word_match_pattern = nil
end

local function update_match()
  if vim.fn.mode() ~= "n" then
    clear_match()
    return
  end

  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" or #word < 2 then
    clear_match()
    return
  end

  local pattern = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
  if vim.w.cursor_word_match_pattern == pattern then
    return
  end

  clear_match()
  vim.w.cursor_word_match_id = vim.fn.matchadd("CursorWord", pattern)
  vim.w.cursor_word_match_pattern = pattern
end

vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "InsertEnter", "ModeChanged", "WinLeave" }, {
  callback = function()
    if vim.fn.mode() == "n" then
      update_match()
    else
      clear_match()
    end
  end,
})
