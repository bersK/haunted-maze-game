@echo off
odin build main_release -define:RAYLIB_SHARED=false -out:build/game_release.exe -collection:third_party=third_party -no-bounds-check -o:speed -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -subsystem:windows
