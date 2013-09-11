::
:: installedSoftware
:: Copyright(c) 2013 Uli Fuchs <ufuchs@gmx.com>
:: MIT Licensed
::

@ECHO OFF

SETLOCAL

SET platform_arch=
SET software_all=software-all.txt
SET software_in_scope=software-in-scope.txt
SET software_to_search=software-to-search.txt
SET exclude_from_scope=exclude_from_scope.bat

:: ONLY VALID for AMD64 systems and only exists on them.
:: Contains all installed 32-bit packages on an AMD64 system.
SET regKey_wow6432node=HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall

:: Contains the packages for a given architecture, e.g. x86 or AMD64
:: - On AMD64 systems this key contains one and only the installed 64-bit
::   programs and _not_ the 32bit/x86 programs.
:: - On x86 systems this key contains all installed programs.
SET regKey_arch=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall

GOTO :MAIN

::
:: DATA SECTION
::

___OUT_OF_SCOPE___
FOR /F "tokens=*" %%_ IN ('type %1 ^
    ) DO (
    ECHO %%_>> %2
)
___EPOCS_FO_TUO___

::
:: SUBROUTINES
::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Aquire the platform architecture. Gets 'AMD64' or 'x86'
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GET_PLATFORM_ARCHITECTURE

    FOR /f "tokens=2* delims= " %%a IN ('reg query ^
        "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" ^
        /v ^
        "PROCESSOR_ARCHITECTURE"') DO SET platform_arch=%%b

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Gets the content from a given registry key and write it to the given file.
::
:: @param1 {regKey} String
:: @param2 {filename} String
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GET_SOFTWARE_BY_REGKEY

    :: drop the unnecessary fields at position 1 and 2
    FOR /F "tokens=1,2* delims= " %%a IN ('reg query %1 /s ^
        ^| findstr /B ".*DisplayName" ') DO (
        :: A space between '%%c >>' writes an extra space at line end
        ECHO %%c>> %2
    )

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Gets _all_ installed software packages on an X86 system
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GET_ALL_SOFTWARE_PACKAGES_FOR_x86

    :: x86(32-bit) packages
    CALL :GET_SOFTWARE_BY_REGKEY %regKey_arch% %software_all%

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Gets _all_ installed software packages on an AMD64 system
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GET_ALL_SOFTWARE_PACKAGES_FOR_AMD64

    :: x86(32-bit) packages
    CALL :GET_SOFTWARE_BY_REGKEY %regKey_wow6432node% %software_all%

    :: AMD64(64-bit) packages
    CALL :GET_SOFTWARE_BY_REGKEY %regKey_arch% %software_all%

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Reading from the registry gets duplicated enties.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:REMOVE_DUPLICATE_ENTRIES

    SETLOCAL enableDelayedExpansion

    SORT %software_all% /o %software_all%

    :: drop duplicates
    SET line=
    SET prevLine=
    FOR /f "tokens=* delims=" %%_ IN ('type %software_all%') DO (
        IF %%_ NEQ !prevLine! (
          ECHO %%_>> temp.txt
          SET prevLine=%%_
        )
    )

    COPY /V /Y temp.txt %software_all% > NUL 2>&1

    DEL temp.txt

    ENDLOCAL

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::
:: @param1 {scriptname} String
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CREATE_EXCLUDE_FROM_SCOPE_SCRIPT

    SETLOCAL EnableDelayedExpansion

    SET software_out_of_scope=software-out-of-scope.txt
    SET line=

    DEL %exclude_from_scope% > NUL 2>&1

    :: Write preample
    ECHO ^@ECHO OFF>> %exclude_from_scope%
    ECHO(>> %exclude_from_scope%
    ECHO ::>> %exclude_from_scope%
    ECHO :: Don't edit this file.>> %exclude_from_scope%
    ECHO :: It will overwritten by the next run.>> %exclude_from_scope%
    ECHO :: Any changes should be made in '%software_out_of_scope%'.>> %exclude_from_scope%
    ECHO ::>> %exclude_from_scope%
    ECHO(>> %exclude_from_scope%

    :: Write script code
    FOR /f "useback delims=" %%_ IN (%1) do (
        IF "%%_" EQU "___EPOCS_FO_TUO___" (
            :: the end
            SET $=
            ENDLOCAL
            GOTO :eof
        )
        IF !$! EQU 2 (
            ECHO(%%_>> %exclude_from_scope%
        )
        IF !$! EQU 1 (
            ECHO(%%_>> %exclude_from_scope%
            FOR /F "tokens=*" %%# IN ('type %software_out_of_scope%') DO (
                SET "line=    ^| findstr /V "%%#" ^"
                ECHO !line!>> %exclude_from_scope%
            )
            SET $=2
        )
        IF "%%_" EQU "___OUT_OF_SCOPE___" (
            :: now read the content of the __DATA__ section
            SET $=1
        )
    )

    ENDLOCAL

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: To increase the performance, all software entries out of scope/interest
:: should be removed.
:: The output is written into %software_in_scope%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:EXCLUDE_SOFTWARE_OUT_OF_SCOPE

    SETLOCAL

    FOR /F "tokens=*" %%_ IN ('type %software_all% ^
        ^| findstr /V "Intel" ^
        ^| findstr /V "Microsoft"
        ^| findstr /V "C++" ^
        ^| findstr /V "SQL" ^
        ^| findstr /V "@" ' ) DO (
        :: A space between '%%c >>' writes an extra space at line end
        ECHO %%_>> %software_in_scope%
    )

    ENDLOCAL

    GOTO :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Gets the software packages which should be scanned.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GET_SOFTWARE_IN_SCOPE

    SETLOCAL enableDelayedExpansion

    :: delete files from last run
    DEL %software_all% > NUL 2>&1
    DEL %software_in_scope% > NUL 2>&1

    CALL :GET_PLATFORM_ARCHITECTURE

    CALL :GET_ALL_SOFTWARE_PACKAGES_FOR_%platform_arch%

    CALL :REMOVE_DUPLICATE_ENTRIES

    CALL :EXCLUDE_SOFTWARE_OUT_OF_SCOPE

    ENDLOCAL

    GOTO :eof

::::::::::::::::::::::::::::::::::::::::
:MAIN
::::::::::::::::::::::::::::::::::::::::

SETLOCAL enableDelayedExpansion

ECHO(
ECHO ^  Aquire installed software from registry.
ECHO ^  This may take a while...
ECHO(

CALL :CREATE_EXCLUDE_FROM_SCOPE_SCRIPT %0

:: Fetch the installed software
CALL :GET_SOFTWARE_IN_SCOPE

:: reads the %software_to_search% file and lines up the items separated by ':'
SET sts=
SET first=0
FOR /f "Delims=" %%_ IN ('type %software_to_search%') DO (
    IF !first! == 0 (
      SET first=1
      SET sts=%%_
    ) ELSE (
      SET sts=!sts!:%%_
    )
)

ECHO(
ECHO ^  Following software is installed:
ECHO ^  ================================
ECHO(

:: look up for the software to search
SET "sp=%sts%"
FOR /F "tokens=*" %%_ IN ('type %software_in_scope%') DO (
    :: iterates over the software names in the search string for each installed software package
    FOR %%S IN ("%sp::=" "%") DO (
        ECHO %%_ | findstr /B "%%~S"
    )
)

ENDLOCAL
