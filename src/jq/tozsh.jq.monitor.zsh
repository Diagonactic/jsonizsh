#!/usr/bin/env zsh


ls tozsh* ../jsonizsh* | entr -c ./tozsh.jq.execute.zsh
