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
    function! true.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.true(1))
    endfunction
    function! true.accepts_an_optional_message()
      call s:assert.true(1, 'error message')
      call s:check_throw('true', [0, 'error message'], 'error message')
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
    function! false.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.false(0))
    endfunction
    function! false.accepts_an_optional_message()
      call s:assert.false(0, 'error message')
      call s:check_throw('false', [1, 'error message'], 'error message')
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
    function! truthy.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.truthy(1))
    endfunction
    function! truthy.accepts_an_optional_message()
      call s:assert.truthy(1, 'error message')
      call s:check_throw('truthy', [0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__falsy__()
    let falsy = themis#suite('.falsy()')
    function! falsy.checks_value_is_zero()
      call s:assert.falsy(0)
      call s:assert.falsy('')
      call s:assert.falsy('0')
    endfunction
    function! falsy.throws_a_report_when_value_is_not_zero_or_not_a_number()
      call s:check_throw('falsy', [1])
      call s:check_throw('falsy', [0.0])
      call s:check_throw('falsy', ['100falsy'])
    endfunction
    function! falsy.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.falsy(0))
    endfunction
    function! falsy.accepts_an_optional_message()
      call s:assert.falsy(0, 'error message')
      call s:check_throw('falsy', [1, 'error message'], 'error message')
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
    function! compare.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.compare(1, '==', 1))
    endfunction
    function! compare.accepts_an_optional_message()
      call s:assert.compare(10, '==', 10, 'error message')
      call s:check_throw('compare', [3, '<', 0, 'error message'], 'error message')
      call s:check_throw('compare', [0, '?', 0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__equals__()
    let equals = themis#suite('.equals()')
    function! equals.checks_actual_equals_to_expect()
      call s:assert.equals(5 + 5, 10)
      call s:assert.equals(2.0 + 5.0, 7)
      call s:assert.equals('hoge' . 'huga', 'hogehuga')
      call s:assert.equals('10', 10)
      call s:assert.equals(range(3), [0, 1, 2])
    endfunction
    function! equals.throws_a_report_when_values_are_not_equivalent()
      call s:check_throw('equals', [1 + 1, 11], 'The equivalent values were expected')
      call s:check_throw('equals', ['hoge', 'HOGE'], 'The equivalent values were expected')
    endfunction
    function! equals.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.equals(1, 1))
    endfunction
    function! equals.accepts_an_optional_message()
      call s:assert.equals(5 + 5, 10, 'error message')
      call s:check_throw('equals', [1 + 1, 11, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__not_equals__()
    let not_equals = themis#suite('.not_equals()')
    function! not_equals.checks_actual_not_equals_to_expect()
      call s:assert.not_equals(5 + 5, 55)
      call s:assert.not_equals('hoge' . 'huga', 'hugahoge')
      call s:assert.not_equals(1.2, 12)
    endfunction
    function! not_equals.throws_a_report_when_values_are_equivalent()
      call s:check_throw('not_equals', [1 + 1, 2], 'Not the equivalent values were expected')
      call s:check_throw('not_equals', ['hoge', 'hoge'], 'Not the equivalent values were expected')
    endfunction
    function! not_equals.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.not_equals(0, 1))
    endfunction
    function! not_equals.accepts_an_optional_message()
      call s:assert.not_equals(5 + 5, 55, 'error message')
      call s:check_throw('not_equals', [1 + 1, 2, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__same__()
    let same = themis#suite('.same()')
    function! same.checks_actual_value_and_expected_value_are_same()
      call s:assert.same(5 + 5, 10)
      call s:assert.same('hoge' . 'huga', 'hogehuga')
      let array = [1]
      call s:assert.same(array, array)
    endfunction
    function! same.throws_a_report_when_values_are_not_same()
      call s:check_throw('same', [10, '10'], 'The same values were expected')
      call s:check_throw('same', [{}, {}], 'The same values were expected')
    endfunction
    function! same.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.same(0, 0))
    endfunction
    function! same.accepts_an_optional_message()
      call s:assert.same(5 + 5, 10, 'error message')
      call s:check_throw('same', [10, '10', 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__not_same__()
    let not_same = themis#suite('.not_same()')
    function! not_same.checks_actual_value_and_expected_value_are_not_same()
      call s:assert.not_same(10.0, 10)
      call s:assert.not_same(10, '10')
      call s:assert.not_same({}, {})
    endfunction
    function! not_same.throws_a_report_when_values_are_same()
      call s:check_throw('not_same', [10, 10], 'Not the same values were expected')
      let array = [1]
      call s:check_throw('not_same', [array, array], 'Not the same values were expected')
    endfunction
    function! not_same.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.not_same({}, {}))
    endfunction
    function! not_same.accepts_an_optional_message()
      call s:assert.not_same(10.0, 10, 'error message')
      call s:check_throw('not_same', [10, 10, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__match__()
    let match = themis#suite('.match()')
    function! match.checks_actual_value_matches_to_pattern()
      call s:assert.match('hoge', '^hoge$')
      call s:assert.match('101010', '^\%(\d\d\)*$')
    endfunction
    function! match.throws_a_report_when_value_does_not_match_to_pattern()
      call s:check_throw('match', ['hoge', 'huga'], 'Match was expected')
    endfunction
    function! match.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.match('hoge', '^hoge$'))
    endfunction
    function! match.accepts_an_optional_message()
      call s:assert.match('hoge', '^hoge$', 'error message')
      call s:check_throw('match', ['hoge', 'huga', 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__not_match__()
    let not_match = themis#suite('.not_match()')
    function! not_match.checks_actual_value_does_not_match_to_pattern()
      call s:assert.not_match('hoge', '^huga$')
    endfunction
    function! not_match.throws_a_report_when_value_matches_to_pattern()
      call s:check_throw('not_match', ['hoge', '^hoge$'], 'Not match was expected')
    endfunction
    function! not_match.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.not_match('hoge', '^huga$'))
    endfunction
    function! not_match.accepts_an_optional_message()
      call s:assert.not_match('hoge', '^huga$', 'error message')
      call s:check_throw('not_match', ['hoge', '^hoge$', 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_number__()
    let is_number = themis#suite('.is_number()')
    function! is_number.checks_type_of_value_is_number()
      call s:assert.is_number(1)
    endfunction
    function! is_number.throws_a_report_when_type_of_value_is_not_number()
      call s:check_throw('is_number', [1.0], 'The type of value was expected to be number')
    endfunction
    function! is_number.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_number(1))
    endfunction
    function! is_number.accepts_an_optional_message()
      call s:assert.is_number(1, 'error message')
      call s:check_throw('is_number', [1.0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_not_number__()
    let is_not_number = themis#suite('.is_not_number()')
    function! is_not_number.checks_type_of_value_is_not_number()
      call s:assert.is_not_number(1.0)
    endfunction
    function! is_not_number.throws_a_report_when_type_of_value_is_number()
      call s:check_throw('is_not_number', [1], 'The type of value was not expected to be number')
    endfunction
    function! is_not_number.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_not_number(1.0))
    endfunction
    function! is_not_number.accepts_an_optional_message()
      call s:assert.is_not_number(1.0, 'error message')
      call s:check_throw('is_not_number', [1, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_string__()
    let is_string = themis#suite('.is_string()')
    function! is_string.checks_type_of_value_is_string()
      call s:assert.is_string('str')
    endfunction
    function! is_string.throws_a_report_when_type_of_value_is_not_string()
      call s:check_throw('is_string', [0], 'The type of value was expected to be string')
    endfunction
    function! is_string.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_string(''))
    endfunction
    function! is_string.accepts_an_optional_message()
      call s:assert.is_string('str', 'error message')
      call s:check_throw('is_string', [0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_not_string__()
    let is_not_string = themis#suite('.is_not_string()')
    function! is_not_string.checks_type_of_value_is_not_string()
      call s:assert.is_not_string(0)
    endfunction
    function! is_not_string.throws_a_report_when_type_of_value_is_string()
      call s:check_throw('is_not_string', ['str'], 'The type of value was not expected to be string')
    endfunction
    function! is_not_string.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_not_string(0))
    endfunction
    function! is_not_string.accepts_an_optional_message()
      call s:assert.is_not_string(0, 'error message')
      call s:check_throw('is_not_string', ['str', 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_func__()
    let is_func = themis#suite('.is_func()')
    function! is_func.checks_type_of_value_is_func()
      call s:assert.is_func(function('function'))
    endfunction
    function! is_func.throws_a_report_when_type_of_value_is_not_func()
      call s:check_throw('is_func', [0], 'The type of value was expected to be func')
    endfunction
    function! is_func.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_func(function('function')))
    endfunction
    function! is_func.accepts_an_optional_message()
      call s:assert.is_func(function('function'), 'error message')
      call s:check_throw('is_func', [0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_not_func__()
    let is_not_func = themis#suite('.is_not_func()')
    function! is_not_func.checks_type_of_value_is_not_func()
      call s:assert.is_not_func(0)
    endfunction
    function! is_not_func.throws_a_report_when_type_of_value_is_func()
      call s:check_throw('is_not_func', [function('function')], 'The type of value was not expected to be func')
    endfunction
    function! is_not_func.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_not_func(0))
    endfunction
    function! is_not_func.accepts_an_optional_message()
      call s:assert.is_not_func(0, 'error message')
      call s:check_throw('is_not_func', [function('function'), 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_list__()
    let is_list = themis#suite('.is_list()')
    function! is_list.checks_type_of_value_is_list()
      call s:assert.is_list([])
    endfunction
    function! is_list.throws_a_report_when_type_of_value_is_not_list()
      call s:check_throw('is_list', [0], 'The type of value was expected to be list')
    endfunction
    function! is_list.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_list([]))
    endfunction
    function! is_list.accepts_an_optional_message()
      call s:assert.is_list([], 'error message')
      call s:check_throw('is_list', [0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_not_list__()
    let is_not_list = themis#suite('.is_not_list()')
    function! is_not_list.checks_type_of_value_is_not_list()
      call s:assert.is_not_list(0)
    endfunction
    function! is_not_list.throws_a_report_when_type_of_value_is_list()
      call s:check_throw('is_not_list', [[]], 'The type of value was not expected to be list')
    endfunction
    function! is_not_list.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_not_list(0))
    endfunction
    function! is_not_list.accepts_an_optional_message()
      call s:assert.is_not_list(0, 'error message')
      call s:check_throw('is_not_list', [[], 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_dict__()
    let is_dict = themis#suite('.is_dict()')
    function! is_dict.checks_type_of_value_is_dict()
      call s:assert.is_dict({})
    endfunction
    function! is_dict.throws_a_report_when_type_of_value_is_not_dict()
      call s:check_throw('is_dict', [0], 'The type of value was expected to be dict')
    endfunction
    function! is_dict.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_dict({}))
    endfunction
    function! is_dict.accepts_an_optional_message()
      call s:assert.is_dict({}, 'error message')
      call s:check_throw('is_dict', [0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_not_dict__()
    let is_not_dict = themis#suite('.is_not_dict()')
    function! is_not_dict.checks_type_of_value_is_not_dict()
      call s:assert.is_not_dict(0)
    endfunction
    function! is_not_dict.throws_a_report_when_type_of_value_is_dict()
      call s:check_throw('is_not_dict', [{}], 'The type of value was not expected to be dict')
    endfunction
    function! is_not_dict.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_not_dict(0))
    endfunction
    function! is_not_dict.accepts_an_optional_message()
      call s:assert.is_not_dict(0, 'error message')
      call s:check_throw('is_not_dict', [{}, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_float__()
    let is_float = themis#suite('.is_float()')
    function! is_float.checks_type_of_value_is_float()
      call s:assert.is_float(1.0)
    endfunction
    function! is_float.throws_a_report_when_type_of_value_is_not_float()
      call s:check_throw('is_float', [0], 'The type of value was expected to be float')
    endfunction
    function! is_float.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_float(0.0))
    endfunction
    function! is_float.accepts_an_optional_message()
      call s:assert.is_float(1.0, 'error message')
      call s:check_throw('is_float', [0, 'error message'], 'error message')
    endfunction
  endfunction

  function! assert.__is_not_float__()
    let is_not_float = themis#suite('.is_not_float()')
    function! is_not_float.checks_type_of_value_is_not_float()
      call s:assert.is_not_float(0)
    endfunction
    function! is_not_float.throws_a_report_when_type_of_value_is_float()
      call s:check_throw('is_not_float', [1.0], 'The type of value was not expected to be float')
    endfunction
    function! is_not_float.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.is_not_float(0))
    endfunction
    function! is_not_float.accepts_an_optional_message()
      call s:assert.is_not_float(0, 'error message')
      call s:check_throw('is_not_float', [1.0, 'error message'], 'error message')
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
    function! type_of.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.type_of('', 'string'))
    endfunction
    function! type_of.accepts_an_optional_message()
      call s:assert.type_of(0, 'Number', 'error message')
      call s:check_throw('type_of', [0.0, 'Number', 'error message'], 'error message')
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
    function! length_of.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.length_of('', 0))
    endfunction
    function! length_of.accepts_an_optional_message()
      call s:assert.length_of('12345', 5, 'error message')
      call s:check_throw('length_of', ['', 1, 'error message'], 'error message')
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
    function! has_key.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.has_key({'foo': 0}, 'foo'))
    endfunction
    function! has_key.accepts_an_optional_message()
      call s:assert.has_key({'foo': 0}, 'foo', 'error message')
      call s:check_throw('has_key', [{}, 'foo', 'error message'], 'error message')
      call s:check_throw('has_key', [[], 0, 'error message'], 'error message')
      call s:check_throw('has_key', ['foo', 0, 'error message'], 'error message')
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
    function! exists.returns_truthy_value_when_check_was_successful()
      call s:assert.truthy(s:assert.exists('*function'))
    endfunction
    function! exists.accepts_an_optional_message()
      let g:the_value_which_exists = 1
      call s:assert.exists('g:the_value_which_exists', 'error message')
      unlet g:the_value_which_exists
      call s:check_throw('exists', ['g:the_value_which_does_not_exist', 'error message'], 'error message')
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
