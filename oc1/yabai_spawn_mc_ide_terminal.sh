#!/bin/sh
open -Fna TextEdit
open -Fna TextEdit
sleep 1

# On my 14" MacBook Pro, creates terminals of dimension 50×16/80×25/160×50 for tier 1/2/3 screens.
if [ "$1" -eq 1 ]; then yabai -m window --resize bottom_right:-395:-210; fi
if [ "$1" -eq 2 ]; then yabai -m window --resize bottom_right:-395:-210; fi
if [ "$1" -eq 3 ]; then yabai -m window --resize bottom_right:-395:-210; fi
