return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup()

      autopairs.get_rule("{"):with_pair(function(opts)
        local filetype = vim.bo[opts.bufnr].filetype
        if filetype ~= "tex" and filetype ~= "plaintex" and filetype ~= "latex" then
          return nil
        end

        -- TeX arguments need a closing brace even before text, punctuation or math.
        -- An escaped brace (\{) is a literal rather than an argument delimiter.
        local before = opts.line:sub(1, opts.col - 1)
        local backslashes = before:match("(\\+)$") or ""
        return #backslashes % 2 == 0
      end, 1)
    end,
  },
}
