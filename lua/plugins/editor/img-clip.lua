return {
  "HakonHarnes/img-clip.nvim",
  ft = { "markdown" },
  opts = {
    default = {
      dir_path = "./",
      use_absolute_path = false,
      relative_to_current_file = true,
    },
    filetypes = {
      markdown = {
        template = "![]($FILE_PATH)",
      },
    },
  },
  keys = {
    {
      "<leader>mp",
      function()
        if vim.fn.has("mac") ~= 1 then
          local ok, err = pcall(vim.cmd, "PasteImage")
          if not ok then
            vim.notify("PasteImage failed: " .. tostring(err), vim.log.levels.WARN)
          end
          return
        end

        local ok_fs, fs = pcall(require, "img-clip.fs")
        local ok_img_clip, img_clip = pcall(require, "img-clip")
        if not ok_fs or not ok_img_clip then
          vim.notify("img-clip is not ready", vim.log.levels.WARN)
          return
        end

        local file_path = fs.get_file_path("png")
        if not file_path then
          return
        end

        local dir_path = vim.fn.fnamemodify(file_path, ":h")
        if not fs.mkdirp(dir_path) then
          vim.notify("Could not create directories: " .. dir_path, vim.log.levels.WARN)
          return
        end

        local script = [[
on run argv
  set outPath to item 1 of argv
  set outFile to POSIX file outPath
  set pngData to the clipboard as «class PNGf»
  set fileRef to open for access outFile with write permission
  set eof of fileRef to 0
  write pngData to fileRef
  close access fileRef
end run
]]

        local output = vim.fn.system({ "osascript", "-", file_path }, script)
        if vim.v.shell_error ~= 0 then
          local msg = vim.fn.trim(output or "")
          if msg == "" then
            msg = "unknown error"
          end
          vim.notify("AppleScript clipboard export failed: " .. msg, vim.log.levels.WARN)
          return
        end

        local pasted = img_clip.paste_image({}, file_path)
        if not pasted then
          vim.notify("Could not insert markup for: " .. file_path, vim.log.levels.WARN)
        end
      end,
      desc = "Paste image from clipboard",
    },
  },
}
