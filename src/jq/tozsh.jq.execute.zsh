#!/usr/bin/env zsh

"${${(%):-%x}:A:h:h}/jsonizsh.zsh" ~/t.txt cluster_result
#./tozsh.jq ~/t.txt | xclip -in -selection clipboard
