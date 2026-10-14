; タグだけでなく本文も HTML に渡し、文中の HTML も装飾を認識する。
((inline
  (html_tag)) @injection.content
  (#set! injection.language "html")
  (#set! injection.include-children))

((latex_block) @injection.content
  (#set! injection.language "latex")
  (#set! injection.include-children))
