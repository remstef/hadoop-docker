#!/bin/bash

if [ -n "$TMUX" ]; then
  tmux new-window 'bash -c "docker compose -f docker-compose-hadoop3-jobimtext.yml logs -f || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-datanode-1 bash || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-resourcemanager-1 bash || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-nodemanager-1 bash || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-namenode-1 bash || echo command failed; exec bash"' \; \
    select-layout tiled \; \
    setw synchronize-panes on \; \
    rename-window hadoop-containers
else
  tmux new-session -d -s dockercontainers \
    'bash -c "docker compose -f docker-compose-hadoop3-jobimtext.yml logs -f || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-datanode-1 bash || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-resourcemanager-1 bash || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-nodemanager-1 bash || echo command failed; exec bash"' \; \
    split-window -h 'bash -c "docker exec -ti hadoopv3-cluster-namenode-1 bash || echo command failed; exec bash"' \; \
    select-layout tiled \; \
    setw synchronize-panes on \; \
    rename-window hadoop-containers \; \
    attach-session
fi




