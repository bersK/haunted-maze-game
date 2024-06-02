#!/usr/bin/env bash

odin build main_release -out:build/game_release.bin -collection:third_party=third_party -no-bounds-check -o:speed -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon
