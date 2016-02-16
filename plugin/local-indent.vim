let s:cpo_save = &cpo
set cpo&vim

highlight default LocalIndentGuide ctermfg=3 ctermbg=0 cterm=inverse guifg=NONE guibg=#e4b65b
command! -nargs=* LocalIndentGuide call localindent#setup_buffer(<f-args>)

let &cpo = s:cpo_save
unlet s:cpo_save
