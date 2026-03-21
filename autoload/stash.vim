let s:named_dir = 'named'
let s:unnamed_dir = 'unnamed'

function stash#Stash(
   \ filename,
   \ buffer_filter = #{buflisted: 1, bufmodified: 1},
   \ name_unnamed = 0,
   \ overwrite = 0
\ )
   try
      call s:PrepareEmptyStashDirectory(a:filename, a:overwrite)
      call s:WipeoutContentBuffers(a:filename)

      let current_buffer = bufnr()
      let exceptions = []

      for bufinfo in getbufinfo(a:buffer_filter)
         execute 'keepjumps buffer ' .bufinfo.bufnr
         if !&modifiable
            continue
         endif

         try
            call s:StashBuffer(a:filename. '/' .s:ContentPath(), a:name_unnamed)
         catch
            let exceptions += [v:exception]
         endtry
      endfor

      if bufexists(current_buffer)
         execute 'keepjumps buffer ' .current_buffer
      endif
      if !empty(exceptions)
         echoerr join(exceptions, '\n')
      endif
   endtry
endfunction

function stash#Restore(filename, optional = 0, name_unnamed = 0)
   try
      let named_dir = a:filename. '/' .s:named_dir
      let unnamed_dir = a:filename. '/' .s:unnamed_dir
      if !(isdirectory(named_dir) && isdirectory(unnamed_dir))
         if a:optional
            return
         else
            echoerr 'E484: Cannot open stash directory'
         endif
      endif

      let current_buffer = bufnr()
      let exceptions = []

      let restore_list =
         \ s:CollectRestoreListInteractively(named_dir, unnamed_dir)

      for [index, dirname] in [[0, named_dir], [1, unnamed_dir]]
         for [content_filename, target] in restore_list[index]
            let content_path = dirname. '/' .content_filename
            try
               call s:RestoreFile(target, content_path, a:name_unnamed)
            catch
               let exceptions += [v:exception]
            endtry
         endfor
      endfor

      execute 'keepjumps buffer ' .current_buffer
      if !empty(exceptions)
         echoerr join(exceptions, '\n')
      endif
   endtry
endfunction

function stash#Delete(filename)
   try
      call delete(a:filename, 'rf')
   endtry
endfunction

function stash#Unname()
   try
      let current_buffer = bufnr()
      let exceptions = []

      for bufinfo in getbufinfo()
         if getbufvar(bufinfo.bufnr, 'stash__is_unnamed', 0)
            execute 'keepjumps buffer ' .bufinfo.bufnr
            try
               0file
               silent execute 'bwipeout ' .s:Bufnr(bufinfo.name)
               unlet b:stash__is_unnamed
            catch
               let exceptions += [v:exception]
            endtry
         endif
      endfor

      execute 'keepjumps buffer ' .current_buffer
      if !empty(exceptions)
         echoerr join(exceptions, '\n')
      endif
   endtry
endfunction

function s:CollectRestoreListInteractively(named_dir, unnamed_dir) abort
   let result = []
   for [named, dirname] in [[1, a:named_dir], [0, a:unnamed_dir]]
      let directory_result = []
      for filename in readdir(dirname)
         let target = named ? s:SourcePath(filename) : ''
         let variant = s:ConfirmRestore(target)
         if variant == s:restore_variants.yes
            let directory_result += [[filename, target]]
         elseif variant == s:restore_variants.cancel
            return [[], []]
         endif
      endfor
      let result += [directory_result]
   endfor
   return result
endfunction

function s:ConfirmRestore(target) abort
   if !empty(a:target)
      let bufnr = s:Bufnr(a:target)
      if getbufvar(bufnr, '&modified')
         execute 'buffer ' .bufnr
         let title = type(a:target) == v:t_number
            \ ? 'There is an open modified buffer for unnamed stashed buffer'
            \ : 'There is an open modified buffer for stashed file'
         let choice = inputlist([
            \ title. ' "' .a:target. '".',
            \ '1. Replace this buffer with a stash',
            \ "2. Don't touch this buffer",
            \ 'q. Cancel stash restoration'
         \ ])
         return choice == 1 ? s:restore_variants.yes :
            \ choice == 2 ? s:restore_variants.no :
            \ s:restore_variants.cancel
      endif
   endif
   return s:restore_variants.yes
endfunction
let s:restore_variants = #{
   \ yes: 0,
   \ no: 1,
   \ cancel: 2
\ }

function s:PrepareEmptyStashDirectory(dirname, overwrite = 0) abort
   if isdirectory(a:dirname)
      if !a:overwrite
         echoerr 'E189: "' .a:dirname. '" exists'
      endif
      call s:EnsureEmptyDirectory(a:dirname. '/' .s:named_dir)
      call s:EnsureEmptyDirectory(a:dirname. '/' .s:unnamed_dir)
   else
      call mkdir(a:dirname, '', 0700)
      call mkdir(a:dirname. '/' .s:named_dir)
      call mkdir(a:dirname. '/' .s:unnamed_dir)
   endif
endfunction

function s:WipeoutContentBuffers(dirname) abort
   let abs_dirname = fnamemodify(a:dirname, ':p')
   for bufinfo in getbufinfo()
      if bufinfo.name[0 : len(abs_dirname) - 1] ==# abs_dirname
         execute 'bwipeout ' .bufinfo.bufnr
      endif
   endfor
endfunction

function s:StashBuffer(content_filename, name_unnamed = 0) abort
   call s:SilentWrite(a:content_filename)
   if &undofile
      let undo_path = undofile(a:content_filename)
      if !empty(undo_path)
         silent execute 'wundo ' .fnameescape(undo_path)
      endif
   endif
   if a:name_unnamed && bufname() == ''
      execute 'file ' .fnameescape(a:content_filename)
      let b:stash__is_unnamed = 1
   endif
endfunction

function s:RestoreFile(filename, content_filename, name_unnamed = 0) abort
   let name_unnamed = a:name_unnamed && empty(a:filename)
   let filename = name_unnamed ? a:content_filename : a:filename

   if empty(filename)
      enew
      call s:RestoreBuffer(a:content_filename, 0)

   else
      if !bufexists(filename)
         execute 'badd ' .fnameescape(filename)
      endif
      let bufnr = s:Bufnr(filename)
      let lnum = getbufinfo(bufnr)[0].lnum
      call setbufvar(bufnr, '&buftype', 'nofile')
      execute 'keepjumps buffer ' .bufnr
      call s:RestoreBuffer(a:content_filename, lnum)
   endif

   if name_unnamed
      let b:stash__is_unnamed = 1
   endif
endfunction

function s:RestoreBuffer(content_filename, lnum = line('.')) abort
   try
      keepjumps %delete _
      execute 'read ++edit ' .fnameescape(a:content_filename)
      keepjumps 0delete _
      if bufname() !=# a:content_filename
         silent execute 'bwipeout ' .s:Bufnr(a:content_filename)
      endif
      setlocal buflisted
   finally
      setlocal buftype=
   endtry
   execute 'keepjumps ' .a:lnum

   if &undofile
      let undo_path = undofile(a:content_filename)
      if filereadable(undo_path)
         silent execute 'rundo ' .fnameescape(undo_path)
      endif
   endif

   silent doautocmd BufRead
endfunction

function s:SilentWrite(filename) abort
   setlocal buftype=nofile
   try
      silent execute 'write ' .fnameescape(a:filename)
      execute 'bwipeout ' .s:Bufnr(a:filename)
   finally
      setlocal buftype=
   endtry
endfunction

function s:EnsureEmptyDirectory(dirname) abort
   call delete(a:dirname, 'rf')
   call mkdir(a:dirname)
endfunction

function s:ContentPath(nr = bufnr()) abort
   let name = bufname(a:nr)
   return name == ''
      \ ? s:unnamed_dir. '/' .a:nr
      \ : s:named_dir. '/' .substitute(fnamemodify(name, ':p'), '/', '%', 'g')
endfunction

function s:SourcePath(content_filename) abort
   return substitute(a:content_filename, '%', '/', 'g')
endfunction

function s:Bufnr(buf) abort
   return type(a:buf) == v:t_number
      \ ? a:buf
      \ : bufnr('^' .s:EscapeMagic(a:buf). '$')
endfunction

function s:EscapeMagic(str) abort
   return escape(a:str, '\.*?~,^${}[]')
endfunction
