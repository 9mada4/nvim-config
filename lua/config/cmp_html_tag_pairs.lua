local M = {}

local tags = {
  "a",
  "abbr",
  "address",
  "article",
  "aside",
  "audio",
  "b",
  "blockquote",
  "body",
  "button",
  "canvas",
  "caption",
  "cite",
  "code",
  "data",
  "datalist",
  "dd",
  "del",
  "details",
  "dfn",
  "dialog",
  "div",
  "dl",
  "dt",
  "em",
  "fieldset",
  "figcaption",
  "figure",
  "footer",
  "form",
  "h1",
  "h2",
  "h3",
  "h4",
  "h5",
  "h6",
  "head",
  "header",
  "html",
  "i",
  "iframe",
  "ins",
  "kbd",
  "label",
  "legend",
  "li",
  "main",
  "map",
  "mark",
  "menu",
  "meter",
  "nav",
  "noscript",
  "object",
  "ol",
  "optgroup",
  "option",
  "output",
  "p",
  "picture",
  "pre",
  "progress",
  "q",
  "rp",
  "rt",
  "ruby",
  "s",
  "samp",
  "script",
  "section",
  "select",
  "small",
  "span",
  "strong",
  "style",
  "sub",
  "summary",
  "sup",
  "table",
  "tbody",
  "td",
  "template",
  "textarea",
  "tfoot",
  "th",
  "thead",
  "time",
  "title",
  "tr",
  "u",
  "ul",
  "var",
  "video",
}

local source = {}

function source:new()
  return setmetatable({}, { __index = self })
end

function source:is_available()
  return vim.bo.filetype == "markdown"
end

function source:get_debug_name()
  return "html_tag_pairs"
end

function source:get_trigger_characters()
  return { "<" }
end

function source:complete(params, callback)
  local line = params.context.cursor_before_line
  local prefix = line:match("<([%w-]+)$")
  local in_tag_context = line:match("<[%w-]*$") ~= nil

  if not prefix or prefix == "" then
    callback({ items = {}, isIncomplete = in_tag_context })
    return
  end

  local items = {}
  for _, tag in ipairs(tags) do
    if vim.startswith(tag, prefix) then
      table.insert(items, {
        label = ("%s /%s"):format(tag, tag),
        filterText = tag,
        insertText = ("%s>$0</%s>"):format(tag, tag),
        insertTextFormat = 2,
        kind = 10,
      })
    end
  end

  callback({ items = items, isIncomplete = in_tag_context })
end

function M.register()
  local cmp = require("cmp")

  for _, registered in ipairs(cmp.get_registered_sources()) do
    if registered.name == "html_tag_pairs" then
      return
    end
  end

  cmp.register_source("html_tag_pairs", source:new())
end

return M
