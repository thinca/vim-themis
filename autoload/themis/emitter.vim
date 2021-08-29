" themis: Event Emitter
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:Emitter = {
\   '_listeners': [],
\ }

function s:Emitter.add_listener(listener) abort
  call add(self._listeners, a:listener)
endfunction

function s:Emitter.get_listeners() abort
  return copy(self._listeners)
endfunction

function s:Emitter.emit(event, ...) abort
  let before_emitting = self.emitting()
  let self._emitting = a:event
  for listener in self._listeners
    call themis#emitter#fire(listener, a:event, a:000)
  endfor
  let self._emitting = before_emitting
endfunction

function s:Emitter.emitting() abort
  return get(self, '_emitting', '')
endfunction

function s:Emitter.remove_listener(listener) abort
  call filter(self._listeners, 'v:val isnot a:listener')
endfunction

function s:Emitter.remove_all_listeners() abort
  let self._listeners = []
endfunction

function themis#emitter#fire(listener, event, args) abort
  if has_key(a:listener, a:event)
    call call(a:listener[a:event], a:args, a:listener)
  elseif has_key(a:listener, '_')
    call call(a:listener['_'], [a:event, a:args], a:listener)
  endif
endfunction

function themis#emitter#new() abort
  return deepcopy(s:Emitter)
endfunction
