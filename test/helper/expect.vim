let s:helper = themis#suite('helper')
let s:expect = themis#helper('expect')

function! s:helper.__expect__()
  let expect = themis#suite('expect')

  function! expect.__to_be_true__()
    let to_be_true = themis#suite('.to_be_true()')
    function! to_be_true.checks_value_is_true()
      call s:expect(1).to_be_true()
    endfunction
    function! to_be_true.checks_value_strictly()
      call s:check_throw('to_be_true', 100)
      call s:check_throw('to_be_true', '1')
      call s:check_throw('to_be_true', 1.0)
      call s:check_throw('to_be_true', 'true')
      call s:check_throw('to_be_true', [1])
    endfunction
  endfunction

  function! expect.__to_be_false__()
    let to_be_false = themis#suite('.to_be_false()')
    function! to_be_false.checks_value_is_false()
      call s:expect(0).to_be_false()
    endfunction
    function! to_be_false.checks_value_strictly()
      call s:check_throw('to_be_false', '')
      call s:check_throw('to_be_false', 0.0)
      call s:check_throw('to_be_false', [])
      call s:check_throw('to_be_false', 'to_be_false')
    endfunction
  endfunction

  function! expect.__to_be_truthy__()
    let to_be_truthy = themis#suite('.to_be_truthy()')
    function! to_be_truthy.checks_value_is_not_zero()
      call s:expect(1).to_be_truthy()
      call s:expect(100).to_be_truthy()
      call s:expect('1').to_be_truthy()
    endfunction
    function! to_be_truthy.throws_a_report_when_value_is_zero_or_not_a_number()
      call s:check_throw('to_be_truthy', 0)
      call s:check_throw('to_be_truthy', 1.0)
      call s:check_throw('to_be_truthy', 'to_be_truthy')
      call s:check_throw('to_be_truthy', '0')
    endfunction
  endfunction

  function! expect.__to_equal__()
    let to_equal = themis#suite('.to_equal()')
    function! to_equal.checks_values_are_equal()
      call s:expect(1).to_equal(1)
      call s:expect('foo').to_equal('foo')
      call s:expect([1, 2, 3]).to_equal([1, 2, 3])
      call s:expect({'foo': 'x'}).to_equal({'foo': 'x'})
    endfunction
    function! to_equal.throws_a_report_when_values_are_differnt()
      call s:check_throw('to_equal', 1, [0])
      call s:check_throw('to_equal', 'foo', ['bar'])
      call s:check_throw('to_equal', [1, 2, 3], [[1, 2]])
      call s:check_throw('to_equal', {'foo': 'x'}, [{'foo': 'y'}])
    endfunction
  endfunction

  function! expect.__to_be_same__()
    let to_be_same = themis#suite('.to_be_same()')
    function! to_be_same.checks_values_have_same_instance()
      call s:expect(1).to_be_same(1)
      let one_list = [1, 2, 3]
      let ref_list = one_list
      call s:expect(one_list).to_be_same(ref_list)
    endfunction
    function! to_be_same.throws_a_report_when_values_are_differnt_instances()
      call s:check_throw('to_be_same', 1, [0])
      call s:check_throw('to_be_same', [1, 2, 3], [[1, 2, 3]])
    endfunction
  endfunction

  function! expect.__to_match__()
    let to_match = themis#suite('.to_match()')
    function! to_match.checks_value_matches_with_regex()
      call s:expect('foo_bar').to_match('oo')
    endfunction
    function! to_match.throws_a_report_when_value_is_not_string()
      call s:check_throw('to_match', 1, ['x'])
    endfunction
    function! to_match.throws_a_report_when_value_does_not_match()
      call s:check_throw('to_match', 'foo_bar', ['^oo'])
    endfunction
  endfunction

  function! expect.__to_have_length__()
    let to_have_length = themis#suite('.to_have_length()')
    function! to_have_length.checks_length_of_string()
      call s:expect('12345').to_have_length(5)
    endfunction
    function! to_have_length.checks_length_of_list()
      call s:expect([1, 2, 3]).to_have_length(3)
    endfunction
    function! to_have_length.checks_length_of_dict()
      call s:expect({'elem': 1}).to_have_length(1)
    endfunction
    function! to_have_length.throws_a_report_when_length_is_mismatch()
      call s:check_throw('to_have_length', '', [1])
      call s:check_throw('to_have_length', [], [1])
      call s:check_throw('to_have_length', {}, [1])
    endfunction
    function! to_have_length.throws_a_report_when_first_argument_is_not_valid()
      call s:check_throw('to_have_length', 0, [1])
    endfunction
  endfunction

  function! expect.__have_key__()
    let to_have_key = themis#suite('.to_have_key()')
    function! to_have_key.checks_key_exists_in_dict()
      call s:expect({'foo': 0}).to_have_key('foo')
    endfunction
    function! to_have_key.checks_index_exists_in_array()
      call s:expect([10, 20, 30]).to_have_key(2)
    endfunction
    function! to_have_key.throws_a_report_when_key_is_not_exist_in_dict()
      call s:check_throw('to_have_key', {}, ['foo'])
    endfunction
    function! to_have_key.throws_a_report_when_index_is_not_exist_in_array()
      call s:check_throw('to_have_key', [], [0])
    endfunction
  endfunction

  function! expect.__to_exist__()
    let to_exist = themis#suite('.to_exist()')
    function! to_exist.before()
      let g:exsiting_variable = 1
    endfunction
    function! to_exist.after()
      unlet g:exsiting_variable
    endfunction
    function! to_exist.checks_existence()
      call s:expect(':w').to_exist()
      call s:expect('*function').to_exist()
      call s:expect('g:exsiting_variable').to_exist()
    endfunction
    function! to_exist.throws_report_when_the_value_does_not_to_exist()
      call s:check_throw('to_exist', 'g:the_value_which_does_not_exist')
    endfunction
  endfunction

  function! expect.__comparison__()
    let comparison = themis#suite('.to_be_greater_than(_or_equal)/.to_be_less_than(_or_equal)')
    function! comparison.checks_value_compared_with_the_other()
      call s:expect(1).to_be_greater_than(0)
      call s:expect('Z').to_be_greater_than('A')
      call s:expect(1).to_be_greater_than_or_equal('1')
      call s:expect(0).to_be_less_than(1)
      call s:expect('0').to_be_less_than('A')
      call s:expect('Z').to_be_less_than_or_equal(0)
    endfunction
    function! comparison.throws_a_report_when_comparison_result_is_false()
      call s:check_throw('to_be_greater_than', 0, [1])
      call s:check_throw('to_be_less_than', 1, [0])
      call s:check_throw('to_be_greater_than_or_equal', 'a', ['z'])
      call s:check_throw('to_be_less_than_or_equal', '1', ['0'])
    endfunction
  endfunction

  function! expect.__to_be_number__()
    let to_be_number = themis#suite('.to_be_number()')
    function! to_be_number.checks_type_of_value()
      call s:expect(0).to_be_number()
    endfunction
    function! to_be_number.throws_a_report_when_type_is_mismatch()
      call s:check_throw('to_be_number', 0.0)
    endfunction
  endfunction

  function! expect.__to_be_string__()
    let to_be_string = themis#suite('.to_be_string()')
    function! to_be_string.checks_type_of_value()
      call s:expect('').to_be_string()
    endfunction
    function! to_be_string.throws_a_report_when_type_is_mismatch()
      call s:check_throw('to_be_string', 0)
    endfunction
  endfunction

  function! expect.__to_be_list__()
    let to_be_list = themis#suite('.to_be_list()')
    function! to_be_list.checks_type_of_value()
      call s:expect([]).to_be_list()
    endfunction
    function! to_be_list.throws_a_report_when_type_is_mismatch()
      call s:check_throw('to_be_list', 0)
    endfunction
  endfunction

  function! expect.__to_be_dict__()
    let to_be_dict = themis#suite('.to_be_dict()')
    function! to_be_dict.checks_type_of_value()
      call s:expect({}).to_be_dict()
    endfunction
    function! to_be_dict.throws_a_report_when_type_is_mismatch()
      call s:check_throw('to_be_dict', 0)
    endfunction
  endfunction

  function! expect.__to_be_func__()
    let to_be_func = themis#suite('.to_be_func()')
    function! to_be_func.checks_type_of_value()
      call s:expect(function('function')).to_be_func()
    endfunction
    function! to_be_func.throws_a_report_when_type_is_mismatch()
      call s:check_throw('to_be_func', 0)
    endfunction
  endfunction

  function! expect.__to_be_float__()
    let to_be_float = themis#suite('.to_be_float()')
    function! to_be_float.checks_type_of_value()
      call s:expect(0.0).to_be_float()
    endfunction
    function! to_be_float.throws_a_report_when_type_is_mismatch()
      call s:check_throw('to_be_float', 0)
    endfunction
  endfunction

  function! expect.__custom_matcher__()
    let custom_matcher = themis#suite('custom matcher')
    function! custom_matcher.before()
      call themis#helper#expect#define_matcher('to_be_one_bigger_than', 'a:1 ==# a:2 + 1',
      \ '(a:not ? "Not e" : "E") . "xpect " . string(a:1) . " to equal " . string(a:2) . "+1"')
      function! Ambigous_equal(a, b)
        return a:a == a:b
      endfunction
      function! My_failure_message(not, name, x, y)
        if a:not
          return 'Not expect ' . string(a:x) . ' == ' . string(a:y)
        else
          return 'Expect ' . string(a:x) . ' == ' . string(a:y)
        endif
      endfunction
      call themis#helper#expect#define_matcher('to_be_similar', function('Ambigous_equal'), function('My_failure_message'))
    endfunction
    function! custom_matcher.after()
      delfunction Ambigous_equal
      delfunction My_failure_message
    endfunction
    function! custom_matcher.can_be_defined()
      call s:expect(2).to_be_one_bigger_than(1)
      call s:expect('2').to_be_similar(2)
    endfunction
    function! custom_matcher.provides_failre_message_definition()
      call s:check_throw('to_be_one_bigger_than', 2, [0], 0, 'themis: report: failure: Expect 2 to equal 0+1')
      call s:check_throw('to_be_one_bigger_than', 2, [1], 1, 'themis: report: failure: Not expect 2 to equal 1+1')
      call s:check_throw('to_be_similar', 2, ['1'], 0, 'themis: report: failure: Expect 2 == ''1''')
      call s:check_throw('to_be_similar', 2, ['2'], 1, 'themis: report: failure: Not expect 2 == ''2''')
    endfunction
  endfunction

endfunction

function! s:check_throw(target, actual, ...)
  let args = a:0 ? a:1 : []
  let not = a:0 > 1 ? (a:2 ==# 1 ? 1 : 0) : 0
  let expected_exception = a:0 > 2 ? a:3 : '^themis:\s*report:\s*failure:.*$'
  let not_thrown = 0
  try
    let expect = not ? s:expect(a:actual).not : s:expect(a:actual)
    call call(expect[a:target], args, expect)
    let not_thrown = 1
  catch
    if v:exception !~# expected_exception
      throw printf('themis: report: failure: expect().%s() threw a wrong exception: %s', a:target, v:exception)
    endif
  endtry
  if not_thrown
    throw printf('themis: report: failure: expect(%s).%s(%s) did not throw any exception.', a:actual, a:target, string(args)[1 : -2])
  endif
endfunction

