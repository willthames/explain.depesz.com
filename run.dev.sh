#!/usr/bin/env bash
# make sure that current dir is project top dir
this_script="${BASH_SOURCE[0]}"
script_directory="$( dirname "${this_script}" )"
work_dir="$( readlink -f "${script_directory}" )"
cd "$work_dir"
# make sure that current dir is project top dir

project_name=explain

# I use ssh-ident tool (https://github.com/ccontavalli/ssh-ident), so I should
# set some env variables.
ssh_ident_agent_env="${HOME}/.ssh/agents/agent-priv-$( hostname -s )"
[[ -e "${ssh_ident_agent_env}" ]] && . "${ssh_ident_agent_env}" > /dev/null

# Check if the session already exist, and if yes - attach, with no changes
tmux has-session -t "${project_name}" 2> /dev/null && exec tmux attach-session -t "${project_name}"

tmux new-session -d -s "$project_name" -n "shell"

tmux new-window -d -n morbo -t 99
tmux split-window -d -t morbo
tmux select-pane -t morbo.0

tmux new-window -d -n "lib" -t 2 -c "${work_dir}/lib/"
tmux new-window -d -n "templates" -t 3 -c "${work_dir}/templates/"

tmux send-keys -t morbo.0 "morbo -v -l http://*:25634 ${project_name}.pl" Enter

tmux send-keys -t morbo.1 "tail -F log/development.log" Enter

tmux send-keys -t lib "vim ." Enter
tmux send-keys -t templates "vim ." Enter

tmux attach-session -t "$project_name"
