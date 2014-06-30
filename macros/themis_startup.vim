" Startup script for external themis command.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:themis_home = expand('<sfile>:h:h')

function! s:append_rtp(path)
  if isdirectory(a:path)
    let path = escape(a:path, '\,')
    let &runtimepath = path . ',' . &runtimepath
    let after = path . '/after'
    if isdirectory(after)
      let &runtimepath .= ',' . after
    endif
  endif
endfunction

function! s:start()
  let g:themis#cmdline = 1
  call s:append_rtp(s:themis_home)
  let args = argv()
  if 0 < len(args)
    " Remove arglist for plain environment
    execute '1,' . len(args) . 'argdelete'
  endif

  return themis#command#start(args)
endfunction

function! s:dump_error(throwpoint, exception)
  new
  try
    if $THEMIS_DEBUG == 1 || a:exception =~# '^Vim'
      $ put =repeat('-', 78)
      $ put ='FATAL ERROR: '
      $ put =themis#util#callstacklines(a:throwpoint)
      let funcs = matchstr(a:throwpoint, '^function\s*\zs.\+\ze,')
      let f = get(split(funcs, '\.\.'), -1)
      if f
        let body = themis#util#funcbody(f, 1)
        $ put =body
      endif
    endif
    $ put ='ERROR: ' . matchstr(a:exception, '^\%(themis:\s*\)\?\zs.*')
  finally
    1 delete _
    % print
  endtry
endfunction

function! s:main()
  let error_count = 0
  try
    let error_count = s:start()
  catch
    let error_count = 1
    call s:dump_error(v:throwpoint, v:exception)
  finally
    if error_count == 0
      qall!
    else
      cquit
    endif
  endtry
endfunction

augroup plugin-themis-startup
  autocmd!
  autocmd VimEnter * call s:main()
augroup END

call s:append_rtp(getcwd())

if v:progname !=# 'gvim'
  " If $DISPLAY is set and the host does not exist,
  " Vim waits for timeout long time.
  " Unset the $DISPLAY to avoid this.
  let $DISPLAY = ''
endif
