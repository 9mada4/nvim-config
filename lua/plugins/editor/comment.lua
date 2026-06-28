return {
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        mappings = false,
      })

      pcall(vim.keymap.del, "n", "gcc")
      pcall(vim.keymap.del, "n", "gbc")

      local function ensure_filetype()
        if vim.bo.filetype ~= "" then
          return
        end

        local ok, detected = pcall(vim.filetype.match, { buf = 0 })
        if ok and detected and detected ~= "" then
          vim.bo.filetype = detected
        end
      end

      local function comment_config()
        local config = vim.deepcopy(require("Comment.config"):get())
        local pre_hook = config.pre_hook

        config.pre_hook = function(ctx)
          local cstr = type(pre_hook) == "function" and pre_hook(ctx) or pre_hook
          if type(cstr) == "string" and cstr:find("%%s") then
            return cstr
          end

          local ok, ft_cstr = pcall(require("Comment.ft").calculate, ctx)
          if ok and type(ft_cstr) == "string" and ft_cstr:find("%%s") then
            return ft_cstr
          end

          cstr = vim.bo.commentstring
          if type(cstr) == "string" and cstr:find("%%s") then
            return cstr
          end

          return "#%s"
        end

        return config
      end

      vim.keymap.set("n", "gc", function()
        ensure_filetype()

        local api = require("Comment.api")
        if vim.v.count == 0 then
          api.toggle.linewise.current(nil, comment_config())
        else
          api.toggle.linewise.count(vim.v.count, comment_config())
        end
      end, { desc = "Comment: toggle current line" })

      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.keymap.set("x", "gc", function()
        ensure_filetype()
        vim.api.nvim_feedkeys(esc, "nx", false)
        require("Comment.api").toggle.linewise(vim.fn.visualmode(), comment_config())
      end, {
        desc = "Comment: toggle selection",
      })
    end,
  },
}
