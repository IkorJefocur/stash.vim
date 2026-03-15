let s:ix = expand("<sfile>:p:r"). "i.vim"
if filereadable(s:ix)
  execute "source " . fnameescape(s:ix)
endif
