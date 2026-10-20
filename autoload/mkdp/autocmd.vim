" Update previews only after a successful save, including :w and :update.
function! mkdp#autocmd#init() abort
  execute 'augroup MKDP_REFRESH_INIT' . bufnr('%')
    autocmd!
    autocmd BufWritePost <buffer> call mkdp#rpc#preview_refresh()
    if g:mkdp_auto_close
      autocmd BufHidden <buffer> call mkdp#rpc#preview_close()
    endif
    autocmd VimLeave * call mkdp#rpc#stop_server()
  augroup END
endfunction

function! mkdp#autocmd#clear_buf() abort
  execute 'autocmd! MKDP_REFRESH_INIT' . bufnr('%')
endfunction
