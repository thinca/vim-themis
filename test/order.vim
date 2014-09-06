let s:order = themis#suite('order')

function! s:order.__test__()
  let test = themis#suite('test')

  function! test.before()
    let self.count = 0
  endfunction
  function! test.first()
    let self.count += 1
    Assert Equals(self.count, 1)
  endfunction
  function! test.second()
    let self.count += 1
    Assert Equals(self.count, 2)
  endfunction
  function! test.third()
    let self.count += 1
    Assert Equals(self.count, 3)
  endfunction
  function! test.fourth()
    let self.count += 1
    Assert Equals(self.count, 4)
  endfunction
  function! test.fifth()
    let self.count += 1
    Assert Equals(self.count, 5)
  endfunction
  function! test.sixth()
    let self.count += 1
    Assert Equals(self.count, 6)
  endfunction
  function! test.seventh()
    let self.count += 1
    Assert Equals(self.count, 7)
  endfunction
  function! test.eighth()
    let self.count += 1
    Assert Equals(self.count, 8)
  endfunction
  function! test.ninth()
    let self.count += 1
    Assert Equals(self.count, 9)
  endfunction
  function! test.tenth()
    let self.count += 1
    Assert Equals(self.count, 10)
  endfunction

endfunction

function! s:order.__nested_bundle__()
  let nested_bundle = themis#suite('nested_bundle')

  function! nested_bundle.before()
    let g:count = 0
  endfunction
  function! nested_bundle.after()
    unlet! g:count
  endfunction
  function! nested_bundle.__first__()
    let first = themis#suite('first')
    function! first.count()
      let g:count += 1
      Assert Equals(g:count, 1)
    endfunction
  endfunction
  function! nested_bundle.__second__()
    let second = themis#suite('second')
    function! second.count()
      let g:count += 1
      Assert Equals(g:count, 2)
    endfunction
  endfunction
  function! nested_bundle.__third__()
    let third = themis#suite('third')
    function! third.count()
      let g:count += 1
      Assert Equals(g:count, 3)
    endfunction
  endfunction
  function! nested_bundle.__fourth__()
    let fourth = themis#suite('fourth')
    function! fourth.count()
      let g:count += 1
      Assert Equals(g:count, 4)
    endfunction
  endfunction
  function! nested_bundle.__fifth__()
    let fifth = themis#suite('fifth')
    function! fifth.count()
      let g:count += 1
      Assert Equals(g:count, 5)
    endfunction
  endfunction

endfunction
