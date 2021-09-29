" themis: helper: Add dependencies.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:helper = {
\   'git_cmd': 'git',
\ }

function s:normalize_git_deps(deps_spec) abort
  let name = ''
  let branch = ''

  let spec_t = type(a:deps_spec)
  if spec_t == type('')
    let url = a:deps_spec
  elseif spec_t == type({})
    let url = a:deps_spec.repos
    let name = get(a:deps_spec, 'name', '')
    let branch = get(a:deps_spec, 'branch', '')
  endif

  if branch is# '' && url =~# '#'
    let [url, branch] = split(url, '#')
  endif
  if name is# ''
    let name = matchstr(url, '.*/\zs.\+')
  endif
  if url =~# '^[[:alnum:]-]\+/[[:alnum:]._-]\+$'
    let url = 'https://github.com/' . url
  endif
  return {
  \   'name': name,
  \   'url': url,
  \   'branch': branch,
  \ }
endfunction

function s:helper.git(deps_spec) abort
  let spec = s:normalize_git_deps(a:deps_spec)
  let repos_path = self.dir . '/' . spec.name
  if !isdirectory(repos_path)
    let branch = spec.branch is# '' ? ''
    \                               : '--branch ' . shellescape(spec.branch)
    let cmd = printf(
    \   '%s clone --quiet --depth 1 %s %s %s',
    \   self.git_cmd, branch, shellescape(spec.url), shellescape(repos_path)
    \ )
    silent let msg = system(cmd)
    if v:shell_error
      throw printf(
      \   "themis: helper/deps: Failed fetching deps: %s\n%s",
      \   cmd, msg
      \ )
    endif
  endif
  call themis#option('runtimepath', repos_path)
endfunction

function themis#helper#deps#new(runner) abort
  let helper = deepcopy(s:helper)
  let filename = a:runner.get_loading_filename()
  if filename isnot# ''
    let helper.dir = fnamemodify(filename, ':h') . '/.deps'
  endif
  return helper
endfunction
