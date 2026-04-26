return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd("colorscheme tokyonight")

        vim.api.nvim_set_hl(0, "htmlH1", { fg = "#82aaff", bold = true }) -- Blue
        vim.api.nvim_set_hl(0, "htmlH2", { fg = "#ff9e64", bg = "none", bold = true }) -- Orange
        vim.api.nvim_set_hl(0, "htmlH3", { fg = "#9ece6a", bold = true }) -- Green
        vim.api.nvim_set_hl(0, "htmlH4", { fg = "#73daca", bold = true }) -- Aqua
        vim.api.nvim_set_hl(0, "htmlH5", { fg = "#bb9af7", bold = true }) -- Magenta
        vim.api.nvim_set_hl(0, "htmlH6", { fg = "#bb9aaa", bold = true }) -- Other

        vim.api.nvim_set_hl(0, "MsgArea", { fg = "#ff9e64", bold = true })

        -- 通常バッファのハイライトには alpha 透過が効かないため、
        -- 背景差をかなり弱くして VSCode 風の薄い見え方に寄せる。
        vim.api.nvim_set_hl(0, "CursorWord", { bg = "#22283b", underline = true, sp = "#46537a" })
    end,
}
