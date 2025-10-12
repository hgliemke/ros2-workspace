#!/bin/bash

# Source workspaces
source /opt/ros/jazzy/setup.bash
source ~/teleop_ws/install/setup.bash

# Start joy node in background
echo "Starting joy node..."
ros2 run joy joy_node &
JOY_PID=$!

# Wait for joy to initialize
sleep 2

# Start teleop
echo "Starting teleop..."
ros2 run teleop_twist_joy teleop_node --ros-args \
  --params-file ~/xbox_correct_config.yaml \
  -r /cmd_vel:=/putin/cmd_vel \
  -p qos_overrides./putin/cmd_vel.publisher.reliability:=best_effort

# Cleanup on exit
echo "Stopping joy node..."
kill $JOY_PID 2>/dev/null
