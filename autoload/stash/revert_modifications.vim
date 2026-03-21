function stash#revert_modifications#RevertModifications()
   let current_buffer = bufnr()
   for bufinfo in getbufinfo(#{buflisted: 1, bufmodified: 1})
      execute 'keepjumps buffer ' .bufinfo.bufnr
      let undotree = undotree()
      let seq = s:UndoLastSaveSeq(undotree.entries, undotree.save_last)
      execute 'undo ' .seq
   endfor
   execute 'keepjumps buffer ' .current_buffer
endfunction

function s:UndoLastSaveSeq(entries, save_last)
   let index = len(a:entries) - 1
   while index >= 0
      let entry = a:entries[index]
      if get(entry, 'save', -1) == a:save_last
         return entry.seq
      endif
      let alt_result = s:UndoLastSaveSeq(get(entry, 'alt', []), a:save_last)
      if alt_result
         return alt_result
      endif
      let index -= 1
   endwhile
   return 0
endfunction
