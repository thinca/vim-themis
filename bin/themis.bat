@echo off
rem Command line utility for themis.vim
rem Version: 1.5.1
rem Author : thinca <thinca+vim@gmail.com>
rem License: zlib License

setlocal

if "%THEMIS_HOME%"== "" call :get_realpath
if "%THEMIS_VIM%"== "" set THEMIS_VIM=vim

set STARTUP_SCRIPT="%THEMIS_HOME%\macros\themis_startup.vim"
if not exist "%STARTUP_SCRIPT%" (
  echo %%THEMIS_HOME%% is not set up correctly. 1>&2
  exit /b 2
)

rem FIXME: Some wrong case exists in passing the argument list.
%THEMIS_VIM% -u NONE -i NONE -n -N -e -s --cmd "source %STARTUP_SCRIPT%" -- %* 2>&1
exit /b %ERRORLEVEL%

:get_realpath
set realpath=..
for /F "skip=5 tokens=2,4 delims=<>[]" %%1 in ('dir /AL "%~pf0" 2^>NUL') do (
    if "%%1" == "SYMLINK" set realpath=%%~2\..\..
)
pushd "%~dp0\%realpath%" 2>NUL || pushd "%realpath%" 2>NUL
set THEMIS_HOME=%CD%
popd
exit /b 0
