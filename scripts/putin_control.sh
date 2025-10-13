#!/bin/bash

# Source ROS2 environment
source /opt/ros/jazzy/setup.bash
source ~/ros2/workspaces/control/install/setup.bash

echo "Starting Putin Robot Control"
echo "============================="

# Kill any existing joy or teleop nodes
pkill -f "joy_node"
pkill -f "teleop_node"

echo "Starting joy node..."
ros2 run joy joy_node &
JOY_PID=$!

sleep 2

echo "Starting teleop..."
ros2 run teleop_twist_joy teleop_node \
  --ros-args \
  --params-file ~/ros2/configs/xbox_correct_config.yaml \
  -r /cmd_vel:=/putin/cmd_vel &
TELEOP_PID=$!

echo ""
echo "Putin control started!"
echo "Joy node PID: $JOY_PID"
echo "Teleop node PID: $TELEOP_PID"
echo ""
echo "Press Ctrl+C to stop..."

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping joy node..."
    kill $JOY_PID 2>/dev/null
    echo "Stopping teleop..."
    kill $TELEOP_PID 2>/dev/null
    echo "Putin control stopped."
    exit 0
}

# Trap Ctrl+C and call cleanup
trap cleanup SIGINT SIGTERM

# Wait for nodes
wait
