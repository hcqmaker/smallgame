@echo off
rem if exist "%~dp0Urho3DPlayer.exe" (set "DEBUG=") else (set "DEBUG=_d")
rem if exist "%~dp0..\share\Urho3D\Resources" (set "OPT1=-pp ..\share\Urho3D\Resources") else (set "OPT1=")
rem if [%1] == [] (set "OPT2=-w -s") else (set "OPT2=")
rem "%~dp0Urho3DPlayer%DEBUG%" Link/Link.lua %OPT1% %OPT2% %*


@echo off
if exist "%~dp0Urho3DPlayer.exe" (set "DEBUG=") else (set "DEBUG=_d")
if [%1] == [] (set "OPT1=-w -s") else (set "OPT1=")
start "" "%~dp0Urho3DPlayer%DEBUG%" Link/Link.lua %OPT1% %*
