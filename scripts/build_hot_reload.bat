@echo off

rem Build game.dll
odin build . -show-timings -use-separate-modules -define:RAYLIB_SHARED=true -build-mode:dll -out:build/game.dll -collection:third_party=third_party -strict-style -vet-unused -vet-using-param -vet-style -vet-semicolon -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem If game.exe already running: Then only compile game.dll and exit cleanly
QPROCESS "game.exe">NUL
IF %ERRORLEVEL% EQU 0 exit /b 1

rem build game.exe
odin build main_hot_reload -use-separate-modules -out:build/game.exe -strict-style -vet-using-param -vet-style -vet-semicolon -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem copy raylib.dll from odin folder to here
if not exist "build/raylib.dll" (
	echo "Please copy raylib.dll from <your_odin_compiler>/vendor/raylib/windows/raylib.dll to the same directory as game.exe"
	exit /b 1
)

exit /b 0
