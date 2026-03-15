function stash#command_shortcuts#PatchSession(
   \ filename = '',
   \ session_filename = v:this_session
\ )
   let filename_arg = fnameescape(a:filename)
   call stash#InjectSessionBeforeBuffers([
      \ 'StashRestore! ' .filename_arg
   \ ], a:session_filename)
   call stash#WriteSessionExtra([
      \ 'StashUnname',
      \ 'StashDelete ' .filename_arg
   \ ], a:session_filename)
endfunction

function stash#command_shortcuts#PreExit(filename = '')
   let filename_arg = fnameescape(a:filename)
   execute 'Stash ' .filename_arg
   if !empty(v:this_session)
      execute 'mksession! ' .fnameescape(v:this_session)
      silent execute 'StashPatchSession ' .filename_arg
   endif
   silent StashRevertModifications
endfunction

function stash#command_shortcuts#PostEnter(filename = '')
   let filename = fnameescape(a:filename)
   execute 'StashRestore! ' .filename
   silent StashUnname
   execute 'StashDelete ' .filename
endfunction
