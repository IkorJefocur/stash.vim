function stash#command_util#Path(filename = '') abort
   let path = !empty(a:filename) ? a:filename :
      \ g:stash#default_filename_as_session && !empty(v:this_session)
         \ ? fnamemodify(v:this_session, ':t:r') :
      \ g:stash#default_filename
   if path[0] != '/'
      if g:stash#directory_as_session && !empty(v:this_session)
         let path = fnamemodify(v:this_session, ':h'). '/' .path
      elseif !empty(g:stash#directory)
         if !isdirectory(g:stash#directory)
            call mkdir(g:stash#directory, '', 0o700)
         endif
         let path = g:stash#directory. '/' .path
      endif
   endif
   return path
endfunction
