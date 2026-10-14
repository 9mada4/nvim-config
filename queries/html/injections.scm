; extends

; Markdown 内の HTML ブロックでも本文の Markdown 構文を解析する。
((text) @injection.content
  (#markdown-buffer?)
  (#set! injection.language "markdown"))
