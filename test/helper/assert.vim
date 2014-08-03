let s:helper = themis#suite('helper')
let s:assert = themis#helper('assert')

function! s:helper.__assert__()
  let assert = themis#suite('assert')

  function! assert.skip()
    call s:check_throw('skip', ['message'], '^themis:\s*report:\s*SKIP:.*message$')
  endfunction

  function! assert.__todo__()
    let todo = themis#suite('.todo()')
    function! todo.throws_a_todo_report_with_message()
      call s:check_throw('todo', ['message'], '^themis:\s*report:\s*todo:.*message$')
    endfunction
    function! todo.can_omit_message()
      call s:check_throw('todo', [], '^themis:\s*report:\s*todo:$')
    endfunction
  endfunction

  function! assert.fail()
    call s:check_throw('fail', ['This test is the fate going failed.'], 'This test is the fate going failed.')
  endfunction

  function! assert.__true__()
    let true = themis#suite('.true()')
    function! true.checks_value_is_true()
      call s:assert.true(1)
    endfunction
    function! true.checks_value_strictly()
      call s:check_throw('true', [100])
      call s:check_throw('true', ['1'])
      call s:check_throw('true', [1.0])
      call s:check_throw('true', ['true'])
      call s:check_throw('true', [[1]])
    endfunction
  endfunction

  function! assert.__false__()
    let false = themis#suite('.false()')
    function! false.checks_value_is_false()
      call s:assert.false(0)
    endfunction
    function! false.checks_value_strictly()
      call s:check_throw('false', [''])
      call s:check_throw('false', [0.0])
      call s:check_throw('false', [[]])
      call s:check_throw('false', ['false'])
    endfunction
  endfunction

  function! assert.__truthy__()
    let truthy = themis#suite('.truthy()')
    function! truthy.checks_value_is_not_zero()
      call s:assert.truthy(1)
      call s:assert.truthy(100)
      call s:assert.truthy('1')
    endfunction
    function! truthy.throws_a_report_when_value_is_zero_or_not_a_number()
      call s:check_throw('truthy', [0])
      call s:check_throw('truthy', [1.0])
      call s:check_throw('truthy', ['truthy'])
      call s:check_throw('truthy', ['0'])
    endfunction
  endfunction

  function! assert.__compare__()
    let compare = themis#suite('.compare()')
    function! compare.does_not_throw_a_report_when_comparing_succeeded()
      call s:assert.compare(10, '==', 10)
      call s:assert.compare('hoge', '==?', 'HOGE')
      call s:assert.compare(1, 'isnot', [])
    endfunction
    function! compare.throws_a_report_when_comparing_failed()
      call s:check_throw('compare', [3, '<', 0], 'The right expression was expected')
      call s:check_throw('compare', [3, '==', []], 'The right expression was expected')
    endfunction
    function! compare.throws_a_report_when_error_occurred()
      call s:check_throw('compare', [0, '?', 0], 'Unexpected error occurred while evaluating the comparing')
      call s:check_throw('compare', [3, '===', []], 'Unexpected error occurred while evaluating the comparing')
    endfunction
  endfunction

  function! assert.__type_of__()
    let type_of = themis#suite('.type_of()')
    function! type_of.checks_type_of_value()
      call s:assert.type_of(0, 'Number')
      call s:assert.type_of('', 'String')
      call s:assert.type_of([], 'List')
      call s:assert.type_of({}, 'Dict')
      call s:assert.type_of({}, 'Dictionary')
      call s:assert.type_of(0.0, 'Float')
    endfunction
    function! type_of.accepts_name_of_type_as_case_insensitive()
      call s:assert.type_of(0, 'Number')
      call s:assert.type_of(0, 'NUMBER')
      call s:assert.type_of(0, 'NuMbEr')
    endfunction
    function! type_of.accepts_one_or_more_names_by_list()
      call s:assert.type_of(0, ['Number'])
      call s:assert.type_of(0, ['Number', 'String', 'Float'])
      call s:assert.type_of('', ['Number', 'String', 'Float'])
      call s:assert.type_of(0.0, ['Number', 'String', 'Float'])
    endfunction
    function! type_of.throws_a_report_when_type_is_mismatch()
      call s:check_throw('type_of', [0.0, 'Number'], 'The type of value was expected to be number')
      call s:check_throw('type_of', ['0', ['Number', 'Float']], 'The type of value was expected to be one of number or float')
    endfunction
  endfunction

  function! assert.__length_of__()
    let length_of = themis#suite('.length_of()')
    function! length_of.checks_length_of_string()
      call s:assert.length_of('12345', 5)
    endfunction
    function! length_of.checks_length_of_list()
      call s:assert.length_of([1, 2, 3], 3)
    endfunction
    function! length_of.checks_length_of_dict()
      call s:assert.length_of({'elem': 1}, 1)
    endfunction
    function! length_of.throws_a_report_when_length_is_mismatch()
      call s:check_throw('length_of', ['', 1], 'The length of value was expected to the specified length')
      call s:check_throw('length_of', [[], 1], 'The length of value was expected to the specified length')
      call s:check_throw('length_of', [{}, 1], 'The length of value was expected to the specified length')
    endfunction
    function! length_of.throws_a_report_when_first_argument_is_not_valid()
      call s:check_throw('length_of', [0, 1], 'The type of value was expected to be one of string, list or dictionary')
    endfunction
  endfunction

  function! assert.__has_key__()
    let has_key = themis#suite('.has_key()')
    function! has_key.checks_key_exists_in_dict()
      call s:assert.has_key({'foo': 0}, 'foo')
    endfunction
    function! has_key.checks_index_exists_in_array()
      call s:assert.has_key([1, 2, 3], 2)
    endfunction
    function! has_key.throws_a_report_when_key_is_not_exist_in_dict()
      call s:check_throw('has_key', [{}, 'foo'], 'The dictionary was expected to have a key')
    endfunction
    function! has_key.throws_a_report_when_index_is_not_exist_in_array()
      call s:check_throw('has_key', [[], 0], 'The array was expected to have a index')
    endfunction
    function! has_key.throws_a_report_when_first_argumentis_not_dict_or_array()
      call s:check_throw('has_key', ['foo', 0], 'The first argument was expected to an array or a dict')
    endfunction
  endfunction

  function! assert.__exists__()
    let exists = themis#suite('.exists()')
    function! exists.throws_report_when_the_value_does_not_exists()
      call s:check_throw('exists', ['g:the_value_which_does_not_exist'], 'The target was expected to exist')
    endfunction
    function! exists.does_not_throw_report_when_the_value_exists()
      let g:the_value_which_exists = 1
      call s:assert.exists('g:the_value_which_exists')
      unlet g:the_value_which_exists
    endfunction
  endfunction

endfunction

function! s:check_throw(target, args, ...)
  let expected_exception = a:0 ? a:1 : '^themis:\s*report:\s*failure:.*$'
  let not_thrown = 0
  try
    call call(s:assert[a:target], a:args, s:assert)
    let not_thrown = 1
  catch
    if v:exception !~# expected_exception
      throw printf('themis: report: failure: assert.%s() threw a wrong exception: %s', a:target, v:exception)
    endif
  endtry
  if not_thrown
    throw printf('themis: report: failure: assert.%s(%s) did not throw any exception.', a:target, string(a:args)[1 : -2])
  endif
endfunction
