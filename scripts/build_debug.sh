#!/usr/bin/env bash

odin build main_release -out:build/game_debug.bin -collection:third_party=third_party -no-bounds-check -debug
