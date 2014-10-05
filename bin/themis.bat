@echo off
rem Command line utility for themis.vim
rem Version: 1.3
rem Author : thinca <thinca+vim@gmail.com>
rem License: zlib License

setlocal

if "%THEMIS_HOME%"== "" set THEMIS_HOME=%~dp0\..
if "%THEMIS_VIM%"== "" set THEMIS_VIM=vim

set STARTUP_SCRIPT="%THEMIS_HOME%\macros\themis_startup.vim"
if not exist "%STARTUP_SCRIPT%" (
  echo %%THEMIS_HOME%% is not set up correctly. 1>&2
  exit /b 2
)

rem FIXME: Some wrong case exists in passing the argument list.
%THEMIS_VIM% -u NONE -i NONE -N -e -s --cmd "source %STARTUP_SCRIPT%" -- %* 2>&1
exit /b %ERRORLEVEL%
