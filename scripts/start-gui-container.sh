#!/usr/bin/env bash
# Start (or create) the TurtleBot3 GUI container and open a shell in it.
# Untested helper: read it before running, and check that it works on your machine.
set -euo pipefail

NAME=tb3_pc_gui
IMAGE=tb3_pc_image

# Let local Docker containers use the PC's display (must be repeated each login/reboot).
xhost +local:docker

# Create the container once, if it does not exist yet.
if ! docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  docker run -dit --network host --name "$NAME" \
    -e DISPLAY="$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    "$IMAGE" bash
fi

# Make sure it is running, then open a shell inside it.
docker start "$NAME" > /dev/null
exec docker exec -it "$NAME" bash
