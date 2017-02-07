function! localindent#setup_buffer(...)
  if !exists('b:localindent')
    let b:localindent = {'orig_cc': &l:colorcolumn, 'use_hl': 0, 'use_cc': 0}
  endif

  for arg in a:000
    if arg =~ 'hl'
      let b:localindent.use_hl = arg[0] == '+'
    elseif arg =~ 'cc'
      let b:localindent.use_cc = arg[0] == '+'
      if !b:localindent.use_cc
        let &l:colorcolumn = b:localindent.orig_cc
      endif
    endif
  endfor

  if b:localindent.use_hl || b:localindent.use_cc
    augroup localindent
      autocmd! * <buffer>
      autocmd CursorMoved,CursorMovedI <buffer> call s:update(0)
      autocmd WinEnter,BufEnter,TextChanged,TextChangedI <buffer> call s:update(1)
      autocmd WinLeave,BufLeave <buffer> call s:clear()
    augroup END
  else
    augroup localindent
      autocmd! * <buffer>
    augroup END
  endif

  call s:update(1)
endfunction


function! s:clear()
  if has_key(b:localindent, 'column')
    for id in b:localindent.column
      silent! call matchdelete(id)
    endfor
    unlet b:localindent.column
  endif

  if b:localindent.use_cc && &l:colorcolumn != b:localindent.orig_cc
    let &l:colorcolumn = b:localindent.orig_cc
  endif
endfunction


function! s:mark_column(line1, line2, column, tab)
  call s:clear()
  if a:line1 == 0 || a:line1 == a:line2 || a:line1 > a:line2
    return
  endif

  let matches = []

  if b:localindent.use_hl
    if exists('*matchaddpos')
      for i in range(a:line1 + 1, a:line2 - 1, 8)
        let group = []
        for j in range(0, 7)
          let c_line = i + j

          if c_line > a:line2 - 1
            break
          endif

          if a:column == 0 && col([c_line, '$']) < 2
            continue
          endif

          call add(group, [c_line, a:column + 1, 1])
        endfor

        let id = matchaddpos('LocalIndentGuide', group, 90)
        call add(matches, id)
      endfor
    else
      " For Vim < 7.4.330
      " Based on profiling, matchaddpos() is faster despite the loop to add
      " multiple positions due to the 8 item limit.
      let first_line = max([1, nextnonblank(a:line1)])
      let last_line = prevnonblank(a:line2)
      let id = matchadd('LocalIndentGuide', '\%(\%>'.first_line.'l\&\%<'.last_line.'l\)\&\%'.(a:column+1).'c', 90)
      call add(matches, id)
    endif
  endif

  let b:localindent.column = matches

  if b:localindent.use_cc
    let c = (a:tab ? a:column * &l:ts : a:column) + 1
    let &l:colorcolumn = (b:localindent.orig_cc ? b:localindent.orig_cc.',' : '').c
  endif
endfunction


function! s:indent_space(expr, delta)
  let indent_char = ' '
  let indent_len = indent(a:expr)
  if !&expandtab
    let indent_char = '\t'
    let indent_len = (indent_len / &l:ts) + a:delta
  else
    let indent_len += &l:sw * a:delta
  endif
  return [indent_char, indent_len]
endfunction


function! s:update(force)
  let force = a:force

  if getline('.') =~# '^\s*$'
    let force = 1
    let cur_line = line('.')
  else
    let cur_line = prevnonblank(line('.'))
  endif

  let w_min = line('w0')
  let w_max = line('w$')

  if w_max == 1
    return
  endif

  if s:indent_space(line('.'), 0)[1] == 0
    if getline(cur_line) == ''
      " Blank lines are ambiguous.  Find a surrounding line that's indented
      " the most.
      let p = prevnonblank(cur_line)
      let n = nextnonblank(cur_line)
      if !p && !n
        return s:clear()
      endif

      if indent(p) > indent(n)
        let cur_line = p
      else
        let cur_line = n
      endif
    else
      return s:clear()
    endif
  endif

  let [indent_char, indent_len] = s:indent_space(cur_line, -1)

  if !force && has_key(b:localindent, 'cache') && has_key(b:localindent, 'column')
    let c_indent = b:localindent.cache[0]
    let c_w_min = b:localindent.cache[1]
    let c_w_max = b:localindent.cache[2]
    let c_min = b:localindent.cache[3]
    let c_max = b:localindent.cache[4]

    if w_min == c_w_min && w_max == c_w_max
          \ && indent_len == c_indent && cur_line >= c_min && cur_line <= c_max
      return
    endif
  endif

  let col_min = cur_line
  let col_max = cur_line

  while col_min >= w_min
    let [_, i_len] = s:indent_space(col_min, -1)
    if i_len < indent_len
      break
    endif
    let col_min = prevnonblank(col_min - 1)
    if col_min == 0
      let col_min = 1
      break
    endif
  endwhile

  while col_max <= w_max
    let [_, i_len] = s:indent_space(col_max, -1)
    if i_len < indent_len
      break
    endif
    let col_max = nextnonblank(col_max + 1)
    if col_max == 0
      let col_max = line('$')
      break
    endif
  endwhile

  let b:localindent.cache = [indent_len, w_min, w_max, col_min, col_max]

  call s:mark_column(col_min, col_max, indent_len, indent_char == '\t')
endfunction
