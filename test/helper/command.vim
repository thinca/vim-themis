let s:helper = themis#suite('helper')
let s:assert = themis#helper('assert')
call themis#helper('command').prefix('Themis').with(s:assert)

function s:helper.__command__() abort
  let command = themis#suite('command')

  function command.__Assert__() abort
    let Assert = themis#suite(':Assert')
    function Assert.check_the_argument_is_truthy() abort
      ThemisAssert 1
      ThemisAssert '1'
    endfunction
    function Assert.can_use_double_quote_in_argument() abort
      ThemisAssert "1"
    endfunction
    function Assert.throw_a_report_when_the_argument_is_not_truthy() abort
      let template = join([
      \   '^themis: report: failure: The truthy value was expected, but it was not the case.',
      \   'Error occurred line:',
      \   '.\{-}',
      \   '',
      \   '    expected: truthy',
      \   '         got: %s$'
      \ ], "\n")
      call s:check_throw('ThemisAssert', [0], printf(template, string(0)))
      call s:check_throw('ThemisAssert', [string([])], printf(template, string([])))
      call s:check_throw('ThemisAssert', [0.0], printf(template, string(0.0)))
    endfunction
    function Assert.can_access_to_function_local_scope() abort
      let x = 10
      ThemisAssert x == 10
    endfunction
    function Assert.can_access_to_with_scope() abort
      let x = 10
      ThemisAssert Equals(x, 10)
      ThemisAssert HasKey({'foo': 0}, 'foo')
    endfunction
  endfunction

  function command.__Throws__() abort
    let Throws = themis#suite(':Throws')
    function Throws.detect_exception_in_expr() abort
      Throws ThrowError('error')
    endfunction
    function Throws.detect_exception_in_command() abort
      Throws :throw 'error'
    endfunction
    function Throws.can_check_exception() abort
      Throws /^error$/ ThrowError('error')
      call s:check_throw('Throws', ['/^error$/ ThrowError("hoge")'], 'An exception was expected, but not thrown')
    endfunction
    function Throws.can_use_double_quote_in_argument() abort
      Throws /^error$/ ThrowError("error")
      Throws /^error$/ :throw "error"
    endfunction
  endfunction

  function command.__Fail__() abort
    let Fail = themis#suite(':Fail')
    function Fail.fails_a_test_with_message() abort
      call s:check_throw('Fail', ['fail message'], 'failure:\s*fail message$')
    endfunction
    function Fail.can_not_omit_message() abort
      call s:check_throw('Fail', [], '{message} of :Fail can not be empty.')
    endfunction
  endfunction

  function command.__TODO__() abort
    let TODO = themis#suite(':TODO')
    function TODO.fails_a_test_as_todo_with_message() abort
      call s:check_throw('TODO', ['fail message'], 'todo:\s*fail message$')
    endfunction
    function TODO.uses_default_message_when_the_message_is_omitted() abort
      call s:check_throw('TODO', [], 'todo:\s*TODO$')
    endfunction
  endfunction

  function command.__Skip__() abort
    let Skip = themis#suite(':Skip')
    function Skip.fails_a_test_with_message() abort
      call s:check_throw('Skip', ['skip message'], 'SKIP:\s*skip message$')
    endfunction
    function Skip.can_not_omit_message() abort
      call s:check_throw('Skip', [], '{message} of :Skip can not be empty.')
    endfunction
  endfunction

  function command.__scope__() abort
    let scope_of_commands = themis#suite('scope of commands')
    function scope_of_commands.__scope__() abort
      let defined = themis#suite('defined')
      function defined.__scope__() abort
        call themis#helper('command').prefix('Defined')
        let scope = themis#suite('scope')
        function scope.command_defined() abort
          call s:assert.cmd_exists(':DefinedAssert')
        endfunction
      endfunction

      let not_defined = themis#suite('not defined')
      function not_defined.__scope__() abort
        let scope = themis#suite('scope')
        function scope.command_defined() abort
          call s:assert.cmd_not_exists(':DefinedAssert')
        endfunction
      endfunction
    endfunction
  endfunction
endfunction

function ThrowError(err) abort
  throw a:err
endfunction

function s:check_throw(cmd, args, expected_exception) abort
  let not_thrown = 0
  let args = join(map(copy(a:args), 'themis#message(v:val)'), ' ')
  try
    execute a:cmd args
    let not_thrown = 1
  catch
    if v:exception !~# a:expected_exception
      throw join([
      \   printf('themis: report: failure: ":%s %s" threw a wrong exception:', a:cmd, args),
      \   '',
      \   printf('    expected exception: "%s"', strtrans(a:expected_exception)),
      \   printf('      thrown exception: "%s"', strtrans(v:exception)),
      \ ], "\n")
    endif
  endtry
  if not_thrown
    throw printf('themis: report: failure: ":%s %s" did not throw any exception.', a:cmd, args)
  endif
endfunction
