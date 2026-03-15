function stash#delete_unnamed_buffers#DeleteUnnamedBuffers(keep_windows = 0)
   let current_window = win_getid()
   windo call s:SwitchToNamedBuffer()
   for bufinfo in getbufinfo(#{buflisted: 1})
      if (
         \ bufinfo.name == ''
         \ && !(a:keep_windows && !empty(win_findbuf(bufinfo.bufnr)))
      \ )
         execute 'bdelete!' .bufinfo.bufnr
      endif
   endfor
   call win_gotoid(current_window)
endfunction

function s:SwitchToNamedBuffer()
   if bufname() == ''
      if bufname('#') != ''
         buffer #
         return
      endif
      let bufnr = bufnr()

      let closest_buffer = 0
      for bufinfo in getbufinfo(#{buflisted: 1})
         if bufinfo.name != '' && (
            \ closest_buffer == 0
            \ || abs(bufnr - bufinfo.bufnr) < abs(bufnr - closest_buffer)
         \ )
            let closest_buffer = bufinfo.bufnr
         endif
      endfor
      if closest_buffer != 0
         execute 'buffer ' .closest_buffer
      endif
   endif
endfunction
