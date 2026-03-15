let s:buffer_read_pattern = '^\('
   \ .'e\(d\(it\?\)\?\)\?'
   \ .'\|enew\?'
   \ .'\|b\(u\(f\(f\(er\?\)\?\)\?\)\?\)\?'
   \ .'\)\(\s\|$\)'
let s:injection_postfix = 'i.vim'
let s:injection = 
   \ readfile(expand('<sfile>:p:h'). '/../../injections/session.vim')

function stash#session#WriteExtra(
   \ script,
   \ session_filename = v:this_session
\ ) abort
   let sx = fnamemodify(a:session_filename, ':p:r'). 'x.vim'
   call writefile(a:script, sx)
endfunction

function stash#session#WriteExtraIfNotExist(
   \ script,
   \ session_filename = v:this_session
\ ) abort
   let sx = fnamemodify(a:session_filename, ':p:r'). 'x.vim'
   if !filereadable(sx)
      call writefile(a:script, sx)
   endif
endfunction

function stash#session#InjectBeforeBuffers(
   \ script,
   \ session_filename = v:this_session
\ ) abort
   let session_script = readfile(a:session_filename)
   let index = s:InjectionIndex(session_script)
   if index != -1
      call extend(session_script, s:injection, index)
      call writefile(session_script, a:session_filename)
   endif
   let session_basename = fnamemodify(a:session_filename, ':p:r')
   let injection_filename = session_basename .s:injection_postfix
   call writefile(a:script, injection_filename)
endfunction

function s:InjectionIndex(session_script) abort
   let index = 0
   let injection_script_line = 0
   let buffer_create_index = -1
   for line in a:session_script
      if line ==# s:injection[injection_script_line]
         let injection_script_line += 1
         if injection_script_line >= len(s:injection)
            return -1
         endif
      else
         let injection_script_line = 0
      endif
      if buffer_create_index == -1 && match(line, s:buffer_read_pattern) != -1
         let buffer_create_index = index
      endif
      let index += 1
   endfor
   return buffer_create_index != -1
      \ ? buffer_create_index
      \ : len(a:session_script)
endfunction
