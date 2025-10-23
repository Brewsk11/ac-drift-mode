@ECHO OFF
ECHO Removing DriftMode files
ECHO:

ECHO Current directory: %~dp0
FOR /F "delims=\" %%A IN ( "%~dp0" ) do SET CWD=%%~nxA

if NOT "%CWD%" == "assettocorsa" (
    ECHO Error: Not in the assettocorsa directory, exiting.
    PAUSE
    EXIT 1
)
ECHO:

@ECHO ON
RMDIR /S /Q apps\lua\drift-mode 2>NUL
RMDIR /S /Q apps\lua\drift-mode-dev 2>NUL
RMDIR /S /Q apps\lua\drift-mode-dev 2>NUL
RMDIR /S /Q apps\lua\drift-mode-editor 2>NUL
RMDIR /S /Q lua\drift-mode 2>NUL
RMDIR /S /Q content\gui\drift-mode 2>NUL
RMDIR /S /Q extension\lua\new-modes\drift-mode 2>NUL
RMDIR /S /Q extension\lua\new-modes\drift-mode-setup 2>NUL
RMDIR /S /Q extension\lua\new-modes\drift-mode-dev 2>NUL
RMDIR /S /Q extension\config\drift-mode 2>NUL
@ECHO OFF

ECHO:
ECHO Done
PAUSE
