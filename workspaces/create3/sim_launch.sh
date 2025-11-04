#!/bin/bash

# Complete Simulation Launch Script for Create3
# Launches Gazebo, activates controllers, and starts teleop
# Usage: ./sim_launch.sh [namespace] [world]
# Default: ./sim_launch.sh putin warehouse

NAMESPACE=${1:-putin}
WORLD=${2:-warehouse}

echo "========================================="
echo "Create3 Complete Simulation Launcher"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "World: $WORLD"
echo ""
echo "Available worlds:"
echo "  - empty (fastest, just ground plane)"
echo "  - warehouse (simple warehouse)"
echo "  - maze (maze environment)"
echo "  - depot (complex warehouse, slower)"
echo ""

# Check if gnome-terminal is available
if ! command -v gnome-terminal &> /dev/null; then
    echo "ERROR: gnome-terminal not found"
    echo "This script requires gnome-terminal to launch multiple windows"
    echo ""
    echo "Install with: sudo apt install gnome-terminal"
    echo ""
    echo "Or run commands manually:"
    echo "  Terminal 1: ros2 launch irobot_create_gz_bringup create3_gz.launch.py namespace:=$NAMESPACE world:=$WORLD"
    echo "  Terminal 2 (after 15s): ros2 control set_controller_state joint_state_broadcaster active --controller-manager /$NAMESPACE/controller_manager"
    echo "  Terminal 3: ros2 control set_controller_state diffdrive_controller active --controller-manager /$NAMESPACE/controller_manager"
    echo "  Terminal 4: ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r /cmd_vel:=/$NAMESPACE/cmd_vel_unstamped"
    exit 1
fi

# Launch Gazebo
echo "[1/4] Launching Gazebo simulation..."
gnome-terminal --title="Gazebo Simulation" -- bash -c "\
echo 'Starting Gazebo...'; \
ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=$NAMESPACE world:=$WORLD; \
exec bash"

# Wait for Gazebo to initialize
echo "[2/4] Waiting for Gazebo to initialize (15 seconds)..."
echo "      (Look for 'Loaded level [default]' in Gazebo window)"
sleep 15

# Activate controllers
echo "[3/4] Activating controllers..."
gnome-terminal --title="Controller Activation" -- bash -c "\
echo 'Activating joint_state_broadcaster...'; \
ros2 control set_controller_state joint_state_broadcaster active \
  --controller-manager /$NAMESPACE/controller_manager && \
echo '✓ joint_state_broadcaster activated' && \
echo '' && \
echo 'Activating diffdrive_controller...' && \
ros2 control set_controller_state diffdrive_controller active \
  --controller-manager /$NAMESPACE/controller_manager && \
echo '✓ diffdrive_controller activated' && \
echo '' && \
echo 'Controller Status:' && \
ros2 control list_controllers --controller-manager /$NAMESPACE/controller_manager && \
echo '' && \
echo 'Controllers activated! Press Enter to close this window...' && \
read; \
exec bash"

# Wait for controllers to activate
sleep 3

# Launch teleop
echo "[4/4] Launching teleop keyboard control..."
gnome-terminal --title="Teleop Keyboard" -- bash -c "\
echo '========================================'; \
echo 'Keyboard Teleop Controls'; \
echo '========================================'; \
echo ''; \
echo 'Moving around:'; \
echo '   u    i    o'; \
echo '   j    k    l'; \
echo '   m    ,    .'; \
echo ''; \
echo 'q/z : increase/decrease max speeds'; \
echo 'w/x : increase/decrease only linear speed'; \
echo 'e/c : increase/decrease only angular speed'; \
echo 'space/k : force stop'; \
echo ''; \
echo 'CTRL-C to quit'; \
echo '========================================'; \
echo ''; \
ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args -r /cmd_vel:=/$NAMESPACE/cmd_vel_unstamped; \
exec bash"

echo ""
echo "========================================="
echo "Simulation Launch Complete!"
echo "========================================="
echo ""
echo "Three windows opened:"
echo "  1. Gazebo - 3D visualization"
echo "  2. Controller Status - one-time activation"
echo "  3. Teleop - keyboard control"
echo ""
echo "In the Teleop window:"
echo "  - Use i/j/k/l/m/, keys to drive"
echo "  - Or use Gazebo GUI teleop panel"
echo ""
echo "To stop:"
echo "  - Press SPACE or k in teleop window"
echo "  - Or Ctrl+C in Gazebo window"
echo ""
