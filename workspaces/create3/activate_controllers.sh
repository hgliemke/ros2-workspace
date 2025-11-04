#!/bin/bash

# Controller Activation Script for Create3 Gazebo Simulation
# Usage: ./activate_controllers.sh [namespace]
# Default namespace: putin

NAMESPACE=${1:-putin}

echo "========================================="
echo "Create3 Controller Activation"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo ""

echo "Waiting for controller manager to be ready..."
sleep 15

echo "Activating controllers..."
echo ""

# Activate joint_state_broadcaster
echo "[1/2] Activating joint_state_broadcaster..."
ros2 control set_controller_state joint_state_broadcaster active \
  --controller-manager /$NAMESPACE/controller_manager

if [ $? -eq 0 ]; then
    echo "✓ joint_state_broadcaster activated successfully"
else
    echo "✗ Failed to activate joint_state_broadcaster"
    echo "   Try waiting longer or check Gazebo is not paused"
fi

echo ""

# Activate diffdrive_controller
echo "[2/2] Activating diffdrive_controller..."
ros2 control set_controller_state diffdrive_controller active \
  --controller-manager /$NAMESPACE/controller_manager

if [ $? -eq 0 ]; then
    echo "✓ diffdrive_controller activated successfully"
else
    echo "✗ Failed to activate diffdrive_controller"
    echo "   Try waiting longer or check Gazebo is not paused"
fi

echo ""
echo "========================================="
echo "Controller Status:"
echo "========================================="
ros2 control list_controllers --controller-manager /$NAMESPACE/controller_manager

echo ""
echo "If both controllers show 'active', you're ready to drive!"
echo "Use: ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r /cmd_vel:=/$NAMESPACE/cmd_vel_unstamped"
