if !exists('g:stash#buffer_filter')
   let g:stash#buffer_filter = #{buflisted: 1, bufmodified: 1}
endif
if !exists('g:stash#name_unnamed')
   let g:stash#name_unnamed = 0
endif
if !exists('g:stash#directory')
   let g:stash#directory = ''
endif
if !exists('g:stash#default_filename')
   let g:stash#default_filename = 'stash'
endif 
if !exists('g:stash#directory_as_session')
   let g:stash#directory_as_session = 0
endif
if !exists('g:stash#default_filename_as_session')
   let g:stash#default_filename_as_session = 0
endif

command -bar -bang -nargs=? Stash call stash#Stash(
   \ stash#command_util#Path(<q-args>),
   \ g:stash#buffer_filter,
   \ g:stash#name_unnamed,
   \ '<bang>' == '!'
\ )
command -bar -bang -nargs=? StashRestore call stash#Restore(
   \ stash#command_util#Path(<q-args>),
   \ '<bang>' == '!',
   \ g:stash#name_unnamed
\ )
command -bar -nargs=? StashDelete
   \ call stash#Delete(stash#command_util#Path(<q-args>))
command -bar StashUnname call stash#Unname()
command -bar StashRevertModifications
   \ call stash#revert_modifications#RevertModifications()
command -bar -bang StashDeleteUnnamed
   \ call stash#delete_unnamed_buffers#DeleteUnnamedBuffers('<bang>' != '!')

function stash#WriteSessionExtra(
   \ script,
   \ session_filename = v:this_session
\ ) abort
   return stash#session#WriteExtra(a:script, a:session_filename)
endfunction
function stash#WriteSessionExtraIfNotExist(
   \ script,
   \ session_filename = v:this_session
\ ) abort
   return stash#session#WriteExtraIfNotExist(a:script, a:session_filename)
endfunction
function stash#InjectSessionBeforeBuffers(
   \ script,
   \ session_filename = v:this_session
\ ) abort
   return stash#session#InjectBeforeBuffers(a:script, a:session_filename)
endfunction

command -bar -nargs=* StashPatchSession call s:PatchSession(<f-args>)
function s:PatchSession(filename = '', session_filename = v:this_session)
   let filename = a:filename == '-' ? '' : a:filename
   call stash#command_shortcuts#PatchSession(filename, a:session_filename)
endfunction
command -nargs=? StashPreExit call stash#command_shortcuts#PreExit(<f-args>)
command -nargs=? StashPreExitSession if !empty(v:this_session)
   \ | call stash#command_shortcuts#PreExit(<f-args>) | endif
command -nargs=? StashPreExitNoSession if empty(v:this_session)
   \ | call stash#command_shortcuts#PreExit(<f-args>) | endif
command -nargs=? StashPostEnter call stash#command_shortcuts#PostEnter(<f-args>)
