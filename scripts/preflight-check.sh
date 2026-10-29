#!/usr/bin/env bash
# Pre-flight readings from the PC side. Run INSIDE the container, with the robot
# software already running on the Pi. It prints readings; you judge them.
# Untested helper: read it before running, and check that it works on your setup.

source /opt/ros/humble/setup.bash

echo "== Nodes (expect the robot's nodes, e.g. /turtlebot3_node) =="
ros2 node list

echo
echo "== Battery voltage (recharge below about 11.5 V) =="
timeout 10 ros2 topic echo /battery_state --once --field voltage

echo
echo "== /scan rate (5 seconds) =="
timeout 5 ros2 topic hz /scan

echo
echo "== /odom rate (5 seconds) =="
timeout 5 ros2 topic hz /odom

echo
echo "== /tf rate (5 seconds) =="
timeout 5 ros2 topic hz /tf

echo
echo "== TF delay (10 seconds). Moving frames should be well under 1 second =="
timeout 10 ros2 run tf2_ros tf2_monitor

echo
echo "== PC clock (compare with the Pi's, see preflight-check-pi.sh) =="
date +%T.%N
