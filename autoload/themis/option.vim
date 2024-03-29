" Themis option utilities.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:default_options = {
\   'target': [],
\   'recursive': 0,
\   'style': 'basic',
\   'reporter': 'tap',
\   'runtimepath': [],
\   'exclude': [],
\ }

function themis#option#default() abort
  return deepcopy(s:default_options)
endfunction

function themis#option#empty_options() abort
  let options = deepcopy(s:default_options)
  let list_t = type([])
  call filter(options, 'type(v:val) == list_t')
  call map(options, '[]')
  return options
endfunction

function themis#option#merge(base, overwriter) abort
  let merged = copy(a:base)
  for [name, value] in items(a:overwriter)
    if type(value) == type([]) && has_key(merged, name)
      let merged[name] += value
    else
      let merged[name] = value
    endif
    unlet value
  endfor
  return merged
endfunction
