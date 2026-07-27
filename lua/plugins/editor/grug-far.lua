return {
  "MagicDuck/grug-far.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("grug-far").setup({})

    local grug_actions = {
      { label = "Replace All", description = "すべての一致箇所を置換する", keys = "r", localleader = true },
      { label = "Quickfix List", description = "検索結果をQuickfixリストへ送る", keys = "q", localleader = true },
      {
        label = "Sync All",
        description = "検索結果で直接編集した内容を対応する全ファイルへ反映する",
        keys = "s",
        localleader = true,
      },
      {
        label = "Sync Line",
        description = "現在の検索結果行で直接編集した内容を対応ファイルへ反映する",
        keys = "l",
        localleader = true,
      },
      { label = "Close", description = "Grug FARを閉じる", keys = "c", localleader = true },
      { label = "Open History", description = "検索・置換の履歴を開く", keys = "t", localleader = true },
      { label = "Add History", description = "現在の検索条件を履歴へ保存する", keys = "a", localleader = true },
      { label = "Refresh", description = "同じ条件で検索結果を更新する", keys = "f", localleader = true },
      { label = "Open Location", description = "選択中の一致箇所を開く", keys = "o", localleader = true },
      { label = "Abort", description = "実行中の検索・置換を中止する", keys = "b", localleader = true },
      { label = "Help", description = "Grug FARのヘルプを表示する", keys = "g?" },
      {
        label = "Toggle Command",
        description = "実行される検索コマンドの表示を切り替える",
        keys = "p",
        localleader = true,
      },
      { label = "Swap Engine", description = "検索エンジンを切り替える", keys = "e", localleader = true },
      { label = "Preview Location", description = "選択中の一致箇所をプレビューする", keys = "i", localleader = true },
      {
        label = "Swap Replacement Interpreter",
        description = "置換文字列の解釈方法を切り替える",
        keys = "x",
        localleader = true,
      },
      { label = "Apply Next", description = "次の一致箇所だけを置換する", keys = "j", localleader = true },
      { label = "Apply Previous", description = "前の一致箇所だけを置換する", keys = "k", localleader = true },
    }

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "grug-far",
      callback = function(event)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(event.buf) then
            return
          end

          vim.keymap.set("n", "<CR>", function()
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local telescope_config = require("telescope.config").values
            local telescope_actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            pickers.new({}, {
              prompt_title = "Grug FAR action",
              finder = finders.new_table({
                results = grug_actions,
                entry_maker = function(action)
                  return {
                    value = action,
                    display = string.format("%-30s %s", action.label, action.description),
                    ordinal = action.label .. " " .. action.description,
                  }
                end,
              }),
              sorter = telescope_config.generic_sorter({}),
              previewer = false,
              sorting_strategy = "ascending",
              layout_strategy = "bottom_pane",
              layout_config = {
                height = 20,
                prompt_position = "top",
              },
              attach_mappings = function(prompt_bufnr)
                telescope_actions.select_default:replace(function()
                  local selection = action_state.get_selected_entry()
                  telescope_actions.close(prompt_bufnr)
                  if not selection then
                    return
                  end

                  vim.schedule(function()
                    local prefix = selection.value.localleader and (vim.g.maplocalleader or "\\") or ""
                    local keys = vim.api.nvim_replace_termcodes(
                      prefix .. selection.value.keys,
                      true,
                      false,
                      true
                    )
                    vim.api.nvim_feedkeys(keys, "m", false)
                  end)
                end)
                return true
              end,
            }):find()
          end, {
            buffer = event.buf,
            desc = "Grug FAR: select action",
          })
        end)
      end,
    })
  end,
  keys = {
    {
      "<leader>sR",
      function()
        require("grug-far").open()
      end,
      desc = "Search and replace in working directory",
    },
  },
}
