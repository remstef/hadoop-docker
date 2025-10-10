#!/usr/bin/env bash

set -e

COMPOSE_FILE=${1:-docker-compose.yml}

echo "Using '${COMPOSE_FILE}'."
if [ ! -f "${COMPOSE_FILE}" ]; then
  echo "Error: Compose file '${COMPOSE_FILE}' not found"
  exit 1
fi

SERVICES=$(docker compose -f ${COMPOSE_FILE} config --services)

# Prepare TMUX command. 
# Check if a tmux session exists; open a new 
# window, or just a new session
if [ -n "$TMUX" ]; then
  TMUX_CMD="tmux new-window"
else
  TMUX_CMD="tmux new-session"
fi

# Start with logs window
TMUX_CMD+=" 'bash -c \"docker compose -f ${COMPOSE_FILE} logs -f || echo command failed; exec bash\"'"

# Add a split pane for each service
i=0
for service in ${SERVICES}; do
  # alternate splitting vertically and horizontically
  split=$([ $((i % 2)) -eq 0 ] && echo "-h" || echo "-v")
  TMUX_CMD+=" \\; split-window ${split} 'bash -c \"docker exec -ti \$(docker compose -f ${COMPOSE_FILE} ps -q ${service}) bash || echo command failed; exec bash\"'"
  i=$((i + 1))
done

# Add final layout commands
TMUX_CMD+=" \\; select-layout tiled \\; rename-window hadoop-containers"

# Execute the constructed command
eval "${TMUX_CMD}"
