return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local line_nr_fg = "#737aa2"
        local cursor_line_nr_fg = "#c0caf5"

        require("tokyonight").setup({
            transparent = true,
            styles = {
                sidebars = "transparent",
                floats = "transparent",
            },
            on_highlights = function(hl)
                for _, group in ipairs({
                    "Normal",
                    "NormalNC",
                    "SignColumn",
                    "EndOfBuffer",
                    "NormalFloat",
                    "FloatBorder",
                    "FloatTitle",
                    "FoldColumn",
                    "LineNr",
                    "CursorLineNr",
                }) do
                    hl[group] = hl[group] or {}
                    hl[group].bg = "NONE"
                end

                hl.ReadableTextBackground = { bg = "#1a1b26" }
                hl.LineNr = { fg = line_nr_fg, bg = "NONE" }
                hl.LineNrAbove = { fg = line_nr_fg, bg = "NONE" }
                hl.LineNrBelow = { fg = line_nr_fg, bg = "NONE" }
                hl.CursorLineNr = { fg = cursor_line_nr_fg, bg = "NONE", bold = true }
            end,
        })

        vim.cmd("colorscheme tokyonight")

        vim.api.nvim_set_hl(0, "htmlH1", { fg = "#82aaff", bold = true }) -- Blue
        vim.api.nvim_set_hl(0, "htmlH2", { fg = "#ff9e64", bg = "NONE", bold = true }) -- Orange
        vim.api.nvim_set_hl(0, "htmlH3", { fg = "#9ece6a", bold = true }) -- Green
        vim.api.nvim_set_hl(0, "htmlH4", { fg = "#73daca", bold = true }) -- Aqua
        vim.api.nvim_set_hl(0, "htmlH5", { fg = "#bb9af7", bold = true }) -- Magenta
        vim.api.nvim_set_hl(0, "htmlH6", { fg = "#bb9aaa", bold = true }) -- Other

        vim.api.nvim_set_hl(0, "MsgArea", { fg = "#ff9e64", bold = true })
        vim.api.nvim_set_hl(0, "ReadableTextBackground", { bg = "#1a1b26" })
        vim.api.nvim_set_hl(0, "LineNr", { fg = line_nr_fg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNrAbove", { fg = line_nr_fg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNrBelow", { fg = line_nr_fg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = cursor_line_nr_fg, bg = "NONE", bold = true })

        -- 通常バッファのハイライトには alpha 透過が効かないため、
        -- 背景差をかなり弱くして VSCode 風の薄い見え方に寄せる。
        vim.api.nvim_set_hl(0, "CursorWord", { bg = "#22283b", underline = true, sp = "#46537a" })

        require("config.readable_text_background").setup({
            highlight = "ReadableTextBackground",
            priority = 1,
        })
    end,
}
