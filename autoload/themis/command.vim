" Themis command line processer.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! themis#command#start(args)
  let [paths, options] = s:parse_args(a:args)
  if get(options, 'exit', 0)
    return
  endif

  if empty(paths)
    let paths = filter(['./test', './t', './spec'], 'isdirectory(v:val)')[: 0]
  endif

  let files = s:paths2files(paths, options.recursive)
  let excludes = join(filter(copy(options.exclude), '!empty(v:val)'), '\|\m')
  if !empty(excludes)
    call filter(files, 'v:val !~# excludes')
  endif
  return themis#run(files, options)
endfunction

" Command line option processer
let s:short_options = {
\   'h': 'help',
\   'r': 'recursive',
\   'v': 'version',
\ }
function! s:parse_args(args)
  let paths = []
  let options = themis#default_options()
  let args = copy(a:args)
  while !empty(args)
    let arg = remove(args, 0)
    if arg =~# '^--'
      call s:process_option(arg[2 :], args, options)
    elseif arg =~# '^-'
      for option in split(arg[1 :], '.\zs')
        if !has_key(s:short_options, option)
          throw 'themis: Unknown option: -' . option
        endif
        call s:process_option(s:short_options[option], args, options)
      endfor
    else
      let paths += [arg]
    endif
  endwhile
  return [paths, options]
endfunction

let s:options = {}
function! s:options.exclude(args, options)
  if empty(a:args)
    throw 'themis: --exclude option requires {pattern}'
  endif
  let a:options.exclude += [remove(a:args, 0)]
endfunction

function! s:options.recursive(args, options)
  let a:options.recursive = 1
endfunction

function! s:options.style(args, options)
  if empty(a:args)
    throw 'themis: --style option requires {name}'
  endif
  let a:options.style = remove(a:args, 0)
endfunction

function! s:options.reporter(args, options)
  if empty(a:args)
    throw 'themis: --reporter option requires {name}'
  endif
  let a:options.reporter = remove(a:args, 0)
endfunction

function! s:options.reporters(args, options)
  let reporters = themis#module#list('reporter')
  call themis#log(join(reporters, "\n"))
  let a:options.exit = 1
endfunction

function! s:options.runtimepath(args, options)
  if empty(a:args)
    throw 'themis: --runtime option requires {path}'
  endif
  let a:options.runtimepath += [remove(a:args, 0)]
endfunction

function! s:options.debug(args, options)
  let $THEMIS_DEBUG = 1
endfunction

function! s:options.help(args, options)
  " TODO: automate options
  call themis#log(join([
  \   'themis: A testing framework for Vim script.',
  \   'Usage: themis [option]... [path]...',
  \   '',
  \   '   --exclude {pattern}      Exclude files',
  \   '-r --recursive              Include sub directories',
  \   '   --reporter {name}        Select a reporter',
  \   '   --runtimepath {path}     Add runtimepath',
  \   '-h --help                   Show this help',
  \ ], "\n"))
  let a:options.exit = 1
endfunction

function! s:options.version(args, options)
  call themis#log('themis version ' . themis#version())
  let a:options.exit = 1
endfunction

function! s:process_option(name, args, options)
  if has_key(s:options, a:name)
    call s:options[a:name](a:args, a:options)
  else
    " FIXME: wrong error for short option
    throw 'themis: Unknown option: --' . a:name
  endif
endfunction

function! s:paths2files(paths, recursive)
  let files = []
  let target_pattern = a:recursive ? '**/*' : '*'
  for path in a:paths
    if isdirectory(path)
      let files += split(globpath(path, target_pattern, 1), "\n")
    else
      let files += [path]
    endif
  endfor
  let mods =  ':p:gs?\\?/?'
  return filter(map(files, 'fnamemodify(v:val, mods)'), '!isdirectory(v:val)')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
