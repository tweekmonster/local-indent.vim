let s:cpo_save = &cpo
set cpo&vim

highlight default LocalIndentGuide ctermfg=3 ctermbg=0 cterm=inverse
command! -nargs=* LocalIndentGuide call localindent#setup_buffer(<f-args>)

let &cpo = s:cpo_save
unlet s:cpo_save
