@ECHO OFF
::
:: Don't edit this file.
:: It will overwritten by the next run.
:: Any changes should be made in 'exclude_from_scope.txt'.
::
FOR /F "tokens=*" %%_ IN ('type %1 ^
    ^| findstr /V "Intel" ^
    ^| findstr /V "Microsoft" ^
    ^| findstr /V "C++" ^
    ^| findstr /V "SQL" ^
    ^| findstr /V "@" ^
    ^| findstr /V "Realtek" ^
    ^| findstr /V "VMware" ^
    ^| findstr /V "Windows Driver" ^
    ') DO (
    ECHO %%_>> %2
)