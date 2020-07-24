@REM /** $.cmd
@REM * Provides safe and convinient way, without temporary files, 3rd party
@REM * executables or twisted tricks, to deliver all parameters to ordinary
@REM * variables ready for use within your batch script
@REM * @see {@link https://github.com/HazelHex/argo}
@REM * @version 1.0
@REM * @author [HazelHex]{@link https://github.com/HazelHex}
@REM * @example
@REM * REM Let's put $.cmd and new batch to same folder. We'll embed these lines
@REM * REM (magic strings) at top of our created batch (optionally after
@REM * REM '@echo off' and 'setlocal' commands):
@REM * @call "%~dp0$.cmd"
@REM * :$
@REM * %$%%1
@REM * %$$%
@REM * REM And we're done! Now if we pass arguments to our script, they will be
@REM * REM available as '$<index>' variable array, i.e. '$1', '$2', etc.
@REM * REM '$0' will contain total number of parameters passed to our batch.
@REM * REM Print our array with this command:
@REM * set $
@REM * @param {string} [%*] - Optional flag string, see documentation
@REM * @returns {errorlevel} success (0), fatal error (9)
@REM */


@REM Routing logic
@REM *************
@REM Forward call to needed phase. Ensure that we always init first
@for /f "tokens=1* delims=<" %%a in ("%~0") do @(
	if "%%b" equ "" goto:init
)
if not defined $n goto:mode
if errorlevel 3 goto:clean
if errorlevel 2 goto:shift
if errorlevel 1 goto:transfer


REM Pipe phase
REM **********
REM Main processing inside pipe instance. All vars and 'setlocal'
REM states set in this phase will be discarded after pipe closes.
REM We use 'doskey' cache and exit codes to communicate with parent

REM Get stdout from other end. We need to disable delayed expansion
REM to prevent problems with '!' and '^'. 'set /p' is unstable here,
REM so using 'for' loop with filter
setlocal disabledelayedexpansion
for /f "delims=" %%$ in ('more') do set "$a=%%$"

REM Something is wrong, we need some input
if not defined $a exit /b 9

REM Enable delayed expansion to manipulate variables safely
setlocal enabledelayedexpansion
REM We assume '/S /D /c' part is always inside 'cmdcmdline'
set "$a=!$a:* /c=!"
REM Cut to useful payload, we know static coordinates
set "$a=!$a:~56,-4!"

REM No more parameters left
if not defined $a exit /b 1

REM Remove surrounding quotes if needed
if "%$n%" neq "*" if "%$dequote:~0,1%" equ "y" if !$a:~0^,1! equ ^" (
	set "$a=!$a:~1!"
	if defined $a if !$a:~-1! equ ^" set "$a=!$a:~0,-1!"
)

REM Parameter is empty after dequote
if not defined $a exit /b 2

REM Double quotes for 'doskey'
set "$a=!$a:"=""!"

REM Put normal string to 'doskey' cache
if not defined $e (
	doskey /exename=$ $%$n%="!$a!"
	exit /b 2
)

REM If delayed expansion was detected, put prepared string
set "$b=!$a:^=^^^^!"
set "$b=%$b:!=^^^!%" !
doskey /exename=$ ;%$n%="!$b!"
exit /b 2


:shift
REM Parameter shifting phase
REM ************************
REM Shift parameters under caller context and go another round

REM We don't need to shift combined string
if "%$n%" equ "*" goto:transfer

set /a "$n += 1"

(2>nul goto
shift /1
goto:$
REM No magic label found, goto above will kill caller batch too
cmd /qd/c exit /b 9
)


:transfer
REM Transfer phase
REM **************
REM Final processing. We transfer parameter strings from 'doskey'
REM cache, set our array vars and clean working environment

REM Empty combined parameter (no shift phase detected)
if "%$n%" equ "*" if not errorlevel 2 (
	set %$array%*=
	set $=
	goto:clean
)

REM Clean procedure will detect error if this var is set
set $=

REM Set total number of parameters as index '0'
if "%$n%" neq "*" set /a "%$array%0 = $n - 1"

REM No parameters to transfer
if "%$n%" neq "*" if %$array%0 equ 0 goto:clean

REM Fill other indexes with actual parameters and clean cache
for /f "%$e% tokens=1* delims==%$d%" %%a in ('doskey /m:$') do (
	set "%$array%%%a=%%~b" !
	doskey /exename=$ %$d%%%a=
)


:clean
REM Clean phase
REM ***********
REM Housekeeping and error detection

set $dequote=
set 0=
set $$=
set $c=
set $d=
set $e=
set $n=
set $p=
set $q=
set $s=

set $array=& set $print=& if not defined $ ( REM Print array to stderr if needed
	if "%$print:~0,1%" equ "y" set %$array% >&2
) else ( REM Fatal error detected
	REM Next two rems are to prevent unsafe code evaluation in case of
	REM fatal error
	set "$=rem \ "
	set "$$=rem \ "
	exit /b 9
)

exit /b 0


:mode
REM Mode selection phase
REM ********************
REM Process call flags and select one of two working modes: combined
REM parameter string or stand-alone parameter vars

REM If we see 'defaults', we ignore all other flags
if "%$p%" neq "%$p:defaults=%" goto:getn

REM Set some flags
set "$p=%$p: =%"
set "$q=%$p:dequote=%"
if "%$p%" neq "%$q%" set "$dequote=yes"
set "$p=%$q:print=%"
if "%$p%" neq "%$q%" set "$print=yes"
if defined $p set "$array=%$p%"

:getn
REM Parse caller file and detect working mode from magic string. Only
REM first occurrence is detected to save time, thus multiple magic
REM strings in one file lead to unpredictable behavior
for /f "tokens=1* delims=%%" %%a in ('findstr /rix "%%\$%%%%[*123456789]" %$c%') do (
	set "$n=%%b"
	goto:setn
)

:setn
REM Magic string not found
if not defined $n goto:clean

exit /b 0


:init
@REM Initialization phase
@REM ********************
@REM Set our working environment inside current context. All vars are
@REM prefixed with '$' (exception is '0' var) and will be cleared after

@REM These defaults can be redefined with call flags
@set "$array=$"
@set "$dequote=no"
@set "$print=no"

@REM These are non-configurable service vars, do not touch them. Some
@REM may contain non-ASCII symbols. Method's core logic is in '$' var
@set 0=^
@set $s=call "%~dp0^<\..\%~nx0" ^>nul
@set "$=@(prompt \ & for %%$ in (%%$) do rem %%cmdcmdline%%%%0%%)%%0%%"
@set "$$=) | %$s:~5% & %$s%"
@set $n=

@REM Detect delayed expansion and make some preparations
@if !^^ equ ! (
	set "$d=;"
	set "$e=eol=$"
) else (
	set "$d=$"
	set $e=
)

@REM Validate call string
@(call if "%%*"===&&call set "$p=%%*"&&set $p|findstr/rixc:"$p=[ 0123456789a-z#$.@[\]_+-]*"||set "$p=defaults")2>nul>&2


@REM Context detection logic
@REM ***********************
@REM Detect if we're being called from other batch (normal behavior),
@REM or running in stand-alone fashion to process and print our own
@REM parameters (testing behavior)
@(2>nul goto
call set "$c=%%"
if defined $c ( REM We're in command context, process own combined parameters
	echo on
	set "$print=yes"
	set "$n=*"
	%$%%*
	%$$%
) else ( REM We're in batch context, detect caller and proceed with mode selection
	call set $c="%%~f0"
	%$s%
)
)
