return {
  "MagicDuck/grug-far.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("grug-far").setup({})

    local grug_actions = {
      { label = "Replace All", keys = "r" },
      { label = "Sync All", keys = "s" },
      { label = "Sync Line", keys = "l" },
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
                    display = action.label,
                    ordinal = action.label,
                  }
                end,
              }),
              sorter = telescope_config.generic_sorter({}),
              attach_mappings = function(prompt_bufnr)
                telescope_actions.select_default:replace(function()
                  local selection = action_state.get_selected_entry()
                  telescope_actions.close(prompt_bufnr)
                  if not selection then
                    return
                  end

                  vim.schedule(function()
                    local localleader = vim.g.maplocalleader or "\\"
                    local keys = vim.api.nvim_replace_termcodes(
                      localleader .. selection.value.keys,
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
