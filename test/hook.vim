let s:hook = themis#suite('hook')

function! s:hook.before()
  let self.runner = themis#runner#new()
  let self.runner.style = themis#module#style('basic', self.runner)
endfunction

function! s:hook.before_each()
  call self.runner.init_bundle()
  let self.bundle = self.runner.add_new_bundle('sample')
  let self.suite = self.bundle.suite
  let self.suite.called = []
endfunction

function! s:hook.is_called_in_order()
  function! self.suite.before()
    let self.called += ['before']
  endfunction
  function! self.suite.before_each()
    let self.called += ['before_each']
  endfunction
  function! self.suite.test1()
    let self.called += ['test1']
  endfunction
  function! self.suite.test2()
    let self.called += ['test2']
  endfunction
  function! self.suite.after_each()
    let self.called += ['after_each']
  endfunction
  function! self.suite.after()
    let self.called += ['after']
  endfunction

  Assert HasKey(self.suite, 'called')
  Assert Equals(self.suite.called, [])
  call self.runner.run_all()
  Assert Equals(self.suite.called,
  \ [
  \   'before',
  \     'before_each',
  \       'test1',
  \     'after_each',
  \     'before_each',
  \       'test2',
  \     'after_each',
  \   'after'
  \ ])
endfunction

function! s:hook.with_parent_is_called_in_order()
  function! self.suite.before()
    let self.called += ['parent_before']
  endfunction
  function! self.suite.before_each()
    let self.called += ['parent_before_each']
  endfunction
  function! self.suite.parent_test()
    let self.called += ['parent_test']
  endfunction
  function! self.suite.after_each()
    let self.called += ['parent_after_each']
  endfunction
  function! self.suite.after()
    let self.called += ['parent_after']
  endfunction

  let child = themis#bundle#new()
  let child.suite.called = self.suite.called
  function! child.suite.before()
    let self.called += ['child_before']
  endfunction
  function! child.suite.before_each()
    let self.called += ['child_before_each']
  endfunction
  function! child.suite.parent_test1()
    let self.called += ['child_test1']
  endfunction
  function! child.suite.parent_test2()
    let self.called += ['child_test2']
  endfunction
  function! child.suite.after_each()
    let self.called += ['child_after_each']
  endfunction
  function! child.suite.after()
    let self.called += ['child_after']
  endfunction
  call self.bundle.add_child(child)

  Assert HasKey(self.suite, 'called')
  Assert Equals(self.suite.called, [])
  call self.runner.run_all()
  Assert Equals(self.suite.called,
  \ [
  \   'parent_before',
  \     'parent_before_each',
  \       'parent_test',
  \     'parent_after_each',
  \     'child_before',
  \       'parent_before_each',
  \         'child_before_each',
  \           'child_test1',
  \         'child_after_each',
  \       'parent_after_each',
  \       'parent_before_each',
  \         'child_before_each',
  \           'child_test2',
  \         'child_after_each',
  \       'parent_after_each',
  \     'child_after',
  \   'parent_after',
  \ ])
endfunction

