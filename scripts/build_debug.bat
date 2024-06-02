@echo off
odin build main_release -define:RAYLIB_SHARED=false -out:build/game_debug.exe -collection:third_party=third_party -debug
