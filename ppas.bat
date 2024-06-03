@echo off
SET THEFILE=C:\DEV\apps\lazarus\lazarus-api_ui\api_ui.exe
echo Linking %THEFILE%
C:\lazarus\fpc\3.2.2\bin\x86_64-win64\ld.exe -b pei-i386 -m i386pe  --gc-sections   --subsystem windows --entry=_WinMainCRTStartup    -o C:\DEV\apps\lazarus\lazarus-api_ui\api_ui.exe C:\DEV\apps\lazarus\lazarus-api_ui\link4772.res
if errorlevel 1 goto linkend
C:\lazarus\fpc\3.2.2\bin\x86_64-win64\postw32.exe --subsystem gui --input C:\DEV\apps\lazarus\lazarus-api_ui\api_ui.exe --stack 16777216
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
