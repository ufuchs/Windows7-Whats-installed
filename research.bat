@echo off

GOTO :RUN

:: http://stackoverflow.com/questions/3068929/how-to-read-file-contents-into-a-variable-in-a-batch-file

:: http://stackoverflow.com/questions/8493493/how-to-loop-thorough-tokens-in-a-string
setlocal EnableDelayedExpansion
set "str=foo bar:biz bang:this & that "^& the other thing!":;How does this work?"
setlocal enableDelayedExpansion
set ^"str=!str::=^

!"
for /f "eol=: delims=" %%S in ("!str!") do (
  if "!!"=="" endlocal
  echo %%S
)

:: http://stackoverflow.com/questions/7308586/using-batch-echo-with-special-characters
for /f "useback delims=" %%_ in (%0) do (
  if "%%_"=="___ATAD___" set $=
  if defined $ echo(%%_
  if "%%_"=="___DATA___" set $=1
)
pause
goto :eof

___DATA____
<?xml version="1.0" encoding="utf-8" ?>
 <root>
   <data id="1">
      hello world
   </data>
 </root>
___ATAD____

:RUN

:: http://stackoverflow.com/questions/11461432/batch-file-to-compare-contents-of-a-text-file
setlocal
for /f %%i in (a.txt) do (
  set %%i=%%i
  )

for /f %%j in (b.txt) do if not defined %%j echo %%j
