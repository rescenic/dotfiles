:::
:::longPath  [/V]  SrcPath  [RtnVar]
:::longPath  /?
:::
:::  Determine the absolute long-name path of source path SrcPath
:::  and return the result in variable RtnVar.
:::
:::  If RtnVar is not specified, then print the result to stderr.
:::
:::  If option /V is specified, then SrcPath is a variable that
:::  contains the source path.
:::
:::  If the first argument is /?, then prints this help to stdout.
:::
:::  The returned ERROLEVEL is 0 upon success, 1 if failure.
:::
:::  longPath.bat version 1.0 was written by Dave Benham
:::
@echo off
setlocal disableDelayedExpansion

:: Load arguments
if "%~1" equ "" goto :noPath
if "%~1" equ "/?" (
  for /f "tokens=* delims=:" %%A in ('findstr "^:::" "%~f0"') do @echo(%%A
  exit /b 0
)
if /i "%~1" equ "/V" (
  setlocal enableDelayedExpansion
  if "%~2" equ "" goto :noPath
  if not defined %~2!! goto :notFound
  for /f "eol=: delims=" %%F in ("!%~2!") do (
    endlocal
    set "sourcePath=%%~fF"
    set "test=%%F"
  )
  shift /1
) else (
  set "sourcePath=%~f1"
  set "test=%~1"
)

:: Validate path
if "%test:**=%" neq "%test%" goto :notFound
if "%test:?=%"  neq "%test%" goto :notFound
if not exist "%test%" goto :notFound

:: Resolve file name, if present
set "returnPath="
if not exist "%sourcePath%\*" (
  for /f "eol=: delims=" %%F in ('dir /b "%sourcePath%"') do set "returnPath=%%~nxF"
  set "sourcePath=%sourcePath%\.."
)

:resolvePath :: one folder at a time
for /f "delims=* tokens=1,2" %%R in (^""%returnPath%"*"%sourcePath%"^") do (
  if "%%~nxS" equ "" for %%P in ("%%~fS%%~R") do (
    if "%~2" equ "" (
      echo %%~P
      exit /b 0
    )
    set "returnPath=%%~P"
    goto :return
  )
  for %%P in ("%%~S\..") do (
    for /f "delims=> tokens=2" %%A in (
      'dir /ad /x "%%~fP"^|findstr /c:">          %%~nxS "'
    ) do for /f "tokens=1*" %%B in ("%%A") do set "returnPath=%%C\%%~R"
  ) || set "returnPath=%%~nxS\%%~R"
  set "sourcePath=%%~dpS."
)
goto :resolvePath

:return
set "delayedPath=%returnPath:^=^^%"
set "delayedPath=%delayedPath:!=^!%"
for /f "delims=* tokens=1,2" %%A in ("%delayedPath%*%returnPath%") do (
  endlocal
  if "!!" equ "" (set "%~2=%%A" !) else set "%~2=%%B"
  exit /b 0
)

:noPath
>&2 echo Missing path argument - Use longPath /? for help.
exit /b 1

:notFound
>&2 echo Path not found
exit /b 1