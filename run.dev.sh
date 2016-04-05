#!/usr/bin/env bash
project_name=explain

tmux new-session -d -s "$project_name" -n "morbo"
tmux move-window -s "morbo" -t "99"
tmux set-buffer "morbo -v -l http://*:25634 explain.pl"$'\n'
tmux paste-buffer -t "morbo"
mkdir -p log
[[ -f "log/development.log" ]] || touch log/development.log
tmux new-window -n "logs"      "tail -F log/development.log"
tmux move-window -s logs -t 98
tmux new-window -n "lib"
tmux new-window -n "templates"
tmux set-buffer $'cd lib\n'
tmux paste-buffer -t lib
tmux set-buffer $'cd templates\n'
tmux paste-buffer -t templates
tmux set-buffer $'vim .\n'
tmux paste-buffer -t libs
tmux paste-buffer -t templates
tmux new-window -n "shell"
tmux attach-session -t "$project_name"
