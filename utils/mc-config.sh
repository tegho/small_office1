#!/bin/bash

mkdir -p ~/.config/mc/

####
cat << FINI > ~/.config/mc/ini
[Midnight-Commander]
use_internal_edit=true
pause_after_run=2
editor_fill_tabs_with_spaces=true
editor_tab_spacing=4

[Layout]
message_visible=false
keybar_visible=false
menubar_visible=false

[Misc]
display_codepage=UTF-8
FINI

####
cat << FPAN > ~/.config/mc/panels.ini
[New Left Panel]
list_format=brief

[New Right Panel]
list_format=brief
FPAN
