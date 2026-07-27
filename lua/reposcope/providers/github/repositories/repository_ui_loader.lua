-- Compatibility surface for reposcope versions that removed this internal module.
-- The config replaces this callback; current reposcope performs its native UI load.
return {
  load_ui_after_fetch = function() end,
}
