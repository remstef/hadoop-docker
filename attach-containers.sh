#!/bin/bash

projname=$(basename $(pwd))

if [ -n "$TMUX" ]; then
  tmux new-window 'bash -c "docker compose -f docker-compose-hadoop3-jobimtext.yml logs -f || echo command failed; exec bash"' \; \
    split-window -h bash -c "docker exec -ti ${projname}-datanode-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-resourcemanager-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-nodemanager-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-historyserver-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-namenode-1 bash || echo command failed; exec bash" \; \
    select-layout tiled \; \
    rename-window hadoop-containers
    # setw synchronize-panes on \; \
else
  tmux new-session -d -s dockercontainers \
    'bash -c "docker compose -f docker-compose-hadoop3-jobimtext.yml logs -f || echo command failed; exec bash"' \; \
    split-window -h bash -c "docker exec -ti ${projname}-datanode-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-resourcemanager-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-nodemanager-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-historyserver-1 bash || echo command failed; exec bash" \; \
    split-window -h bash -c "docker exec -ti ${projname}-namenode-1 bash || echo command failed; exec bash" \; \
    select-layout tiled \; \
    rename-window hadoop-containers \; \
    attach-session
    # setw synchronize-panes on \; \
fi




