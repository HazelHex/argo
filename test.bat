@goto:init
_________________________________________v1.0___2020-07-24____________
-----------~+++- Batut: batch unit tester by HazelHex -+++~-----------
**********************************************************************
https://github.com/HazelHex/argo
**********************************************************************
Enter raw data you want to test after the empty line below, finish
with an empty line again to define the end of data.
One line is one test parameter. No need to escape or quote anything
(except for the usual cmd.exe escaping rules). These strings will be
passed as they are to the command line as the subject's arguments.
You can store some strings before the start or after the end of data
for later tests. Just remember that a parser searches only for strings
between the first two line feeds of this file.
Change another options underneath, at the ':init' section.
**********************************************************************

letters
0123456789
word123
text with spaces 123 and 456 nospace789
symbols `~!@#$*()-_=+[{]}\:;'",./?
white		 	 spaces
"
^"
""
^"^"
^""
"^"
^^^"^^^"
^^^"^^^"^^^"
"quoted text with spaces"
"odd"quoted"text
^"caret^"quoted^"text
^"another one^"
poison unquoted ^&^|^<^>%!^^
poison quoted "&|<>%!^"
caret^^"caret^
caret_at_the_end^^
"^^ ^^"
quote_mangling"|x"^|y
quote_mangling^&"&
^&echo/UHaxxed
"&echo/UHaxxed
"&echo"^&echo/Still haxxed^&
^&echo/"&echo/Still haxxed&
^|findstr
"|findstr
^|^|echo/or
^>nul
2^>^&1
"|^^&
"||^^&
"|^&&
"|^^||
"|^||
"&&^^||
^|"|^^&
^|"||^^&
^|"|^&&
^|"|^^||
^|"|^||
^|"&&^^||
^|"|^^&"
^|"||^^&"
^|"|^&&"
^|"|^^||"
^|"|^||"
^|"&&^^||"
"|^^&"^|
"||^^&"^|
"|^&&"^|
"|^^||"^|
"|^||"^|
"&&^^||"^|
REM
/c
/k
/r
/?
//?
%%0%% ^%0^% ^%$^%
%$ %~$ %a %~fa %%$ %%~$ %%a %%~fa
%1 %%1 %~f1 %%~f1
%* %%* %~* %%~*
^%COMSPEC^%
^%cmdcmdline^%
A very long and boring text about cmd caret "^^" + "!" escaping rules; and how the caret with enabled delayed expansion needs 4 carets without quotes = ^^^^!, and 2 carets with quotes = "^^!" to escape itself with an exclamation mark presented on the same string...
^^! !^^ ^!^ ^^^^! !^^^^ ^^!^^
"!" "^^!" "!^^" "^^!^^" "!^^^^"
!between_exclamation_marks!
SHOUT!!!!!!!!!!!!!!!!!!!
33 carets ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
33 carets quoted "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
some binary symbols below
xy
xy
xy



:init
@echo off
REM Running code starts here
setlocal disabledelayedexpansion

REM ********************* Change options here ************************
REM Full path to testing subject
set subject="%~dp0$.cmd"

REM Enable call mode. Instead of new 'cmd /c' instance, call from this
REM file will be made. In other words, 'call=no' means run in command
REM context, and 'call=yes' means run in batch context.
set "call=no"

REM Enable delayed expansion while testing, useful only when 'call=no'
set "delayed=no"
REM ******************************************************************

echo/[36m
echo/---~+++- Batut v1.0, by HazelHex -+++~---
echo/https://github.com/HazelHex/argo
echo/[m

REM Initialize environment
if not exist %subject% (
	echo/[31mERROR: The subject file does not exist[m
	exit /b 2
)

set s=
if "%delayed:~0,1%" equ "y" (
	set "delayed=v"
) else set delayed=

REM Parse myself and find some strings for tests
for /f "tokens=1* delims=:" %%n in ('findstr /rinx "^$ ^:init$" "%~f0"') do (
	if "%%o" equ "init" (
		echo/[31mERROR: No raw data found, enclose it between the two empty lines at the beginning of this file[m
		exit /b 2
	)
	if defined s (
		set /a "e = %%n"
		goto:get
	) else set /a "s = %%n"
)


:get
REM Count parameter offsets
set /a "e -= s + 1"
set /a "s -= s * 2 - 1"

if %e% equ 0 (
	echo/[31mERROR: No raw data found, make sure you don't have redundant empty lines at the beginning of this file[m
	exit /b 2
)

REM Get parameters
<"%~f0" (
	for /l %%n in (%s%,1,%e%) do (
		if %%n lss 1 (
			set /p=
		) else set /p p%%n=
	)
)

REM Print headers
echo/[33mSubject file is %subject%
<nul set /p="Call mode is "
if "%call:~0,1%" equ "y" (
	echo/[44mon[40m
) else (
	echo/[44moff[40m
	<nul set /p="Delayed expansion is "
	if defined delayed (
		echo/[44mon[40m
	) else echo/[44moff[40m
)
echo/Total number of parameters: %e%[m
echo/[32m
echo/Performing tests...
echo/[m

REM Main testing loop
for /l %%n in (1,1,%e%) do (
	call:test %%n
	echo/
)

echo/[32mFinished![m
exit /b 0


:test
REM Main testing procedure
setlocal enabledelayedexpansion
set "p=!p%1!"
echo/[32m%1: [[33m!p![32m][m

REM Context selector
if "%call:~0,1%" equ "y" (
	call %subject% !p!
) else cmd /%delayed%d/c "%subject% !p!"

set /a "c = %errorlevel%"

<nul set /p="[32mExit code: "
if %c% geq 1 <nul set /p="[31m"
echo/%c%[m

endlocal
exit /b 0
