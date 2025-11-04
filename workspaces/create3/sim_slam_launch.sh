#!/bin/bash

# SLAM Testing Launch Script for Create3 Simulation
# Launches Gazebo, activates controllers, starts SLAM, RViz, and teleop
# Usage: ./sim_slam_launch.sh [namespace] [world]
# Default: ./sim_slam_launch.sh putin warehouse

NAMESPACE=${1:-putin}
WORLD=${2:-warehouse}

echo "========================================="
echo "Create3 SLAM Simulation Launcher"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "World: $WORLD"
echo ""

# Check dependencies
if ! command -v gnome-terminal &> /dev/null; then
    echo "ERROR: gnome-terminal not found"
    echo "Install with: sudo apt install gnome-terminal"
    exit 1
fi

# Check if slam_toolbox is installed
if ! ros2 pkg list | grep -q slam_toolbox; then
    echo "ERROR: slam_toolbox not found"
    echo "Install with: sudo apt install ros-jazzy-slam-toolbox"
    exit 1
fi

# Check if create3_lidar_slam package exists
if ! ros2 pkg prefix create3_lidar_slam &> /dev/null; then
    echo "WARNING: create3_lidar_slam package not found"
    echo "Using default SLAM configuration"
    SLAM_CONFIG=""
else
    SLAM_CONFIG="--params-file \$(ros2 pkg prefix create3_lidar_slam)/share/create3_lidar_slam/config/mapper_params_online_async.yaml"
fi

echo "Launching SLAM simulation in 5 seconds..."
echo "(Make sure your workspace is sourced!)"
sleep 5

# Launch Gazebo
echo "[1/5] Launching Gazebo simulation..."
gnome-terminal --title="Gazebo Simulation" -- bash -c "\
echo 'Starting Gazebo...'; \
ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=$NAMESPACE world:=$WORLD; \
exec bash"

# Wait for Gazebo
echo "[2/5] Waiting for Gazebo to initialize (15 seconds)..."
sleep 15

# Activate controllers
echo "[3/5] Activating controllers..."
gnome-terminal --title="Controller Activation" -- bash -c "\
echo 'Activating controllers...'; \
sleep 2; \
ros2 control set_controller_state joint_state_broadcaster active \
  --controller-manager /$NAMESPACE/controller_manager && \
ros2 control set_controller_state diffdrive_controller active \
  --controller-manager /$NAMESPACE/controller_manager && \
echo '✓ Controllers activated' && \
ros2 control list_controllers --controller-manager /$NAMESPACE/controller_manager && \
echo '' && \
echo 'Press Enter to close...' && \
read; \
exec bash"

sleep 5

# Launch SLAM Toolbox
echo "[4/5] Launching SLAM Toolbox..."
gnome-terminal --title="SLAM Toolbox" -- bash -c "\
echo 'Starting SLAM Toolbox...'; \
echo ''; \
ros2 run slam_toolbox async_slam_toolbox_node \
  --ros-args \
  $SLAM_CONFIG \
  -p use_sim_time:=true \
  -p scan_topic:=/$NAMESPACE/scan & \
SLAM_PID=\$!; \
echo 'Waiting for SLAM to initialize...'; \
sleep 5; \
echo ''; \
echo 'Configuring SLAM lifecycle...'; \
ros2 lifecycle set /slam_toolbox configure && \
echo '✓ SLAM configured' && \
echo 'Activating SLAM...'; \
ros2 lifecycle set /slam_toolbox activate && \
echo '✓ SLAM activated' && \
echo ''; \
echo 'SLAM is now running!'; \
echo 'Map will build as the robot moves.'; \
echo ''; \
wait \$SLAM_PID; \
exec bash"

sleep 7

# Launch RViz
echo "[5/5] Launching RViz..."
gnome-terminal --title="RViz Visualization" -- bash -c "\
echo 'Starting RViz...'; \
echo ''; \
echo 'Configure RViz:'; \
echo '1. Set Fixed Frame to: map'; \
echo '2. Add Map display (topic: /map)'; \
echo '3. Add LaserScan (topic: /$NAMESPACE/scan)'; \
echo '4. Add RobotModel'; \
echo '5. Add TF'; \
echo ''; \
rviz2 --ros-args -p use_sim_time:=true; \
exec bash"

sleep 3

# Launch teleop
echo ""
echo "Launching keyboard teleop..."
gnome-terminal --title="Teleop Keyboard" -- bash -c "\
echo '========================================'; \
echo 'SLAM Mapping Mode - Drive Around!'; \
echo '========================================'; \
echo ''; \
echo 'Drive the robot to build the map.'; \
echo 'Watch the map build in RViz.'; \
echo ''; \
echo 'Controls:'; \
echo '   u    i    o'; \
echo '   j    k    l'; \
echo '   m    ,    .'; \
echo ''; \
echo 'To save the map later:'; \
echo '  ros2 service call /slam_toolbox/serialize_map \\'; \
echo '    slam_toolbox/srv/SerializePoseGraph \\'; \
echo '    \"{filename: \\'/home/\$USER/maps/my_map\\'}\"; \
echo ''; \
echo 'Or use map_server:'; \
echo '  ros2 run nav2_map_server map_saver_cli -f ~/maps/my_map'; \
echo ''; \
echo '========================================'; \
echo ''; \
ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args -r /cmd_vel:=/$NAMESPACE/cmd_vel_unstamped; \
exec bash"

echo ""
echo "========================================="
echo "SLAM Simulation Launch Complete!"
echo "========================================="
echo ""
echo "Windows opened:"
echo "  1. Gazebo - Robot simulation"
echo "  2. Controllers - Status display"
echo "  3. SLAM Toolbox - Mapping backend"
echo "  4. RViz - Map visualization"
echo "  5. Teleop - Keyboard control"
echo ""
echo "Next steps:"
echo "  1. Configure RViz displays (see RViz window)"
echo "  2. Drive robot around with teleop"
echo "  3. Watch map build in RViz"
echo "  4. Save map when done"
echo ""
echo "NOTE: Default Create3 model has no lidar!"
echo "You may need to add obstacles manually or"
echo "use a custom robot model with lidar sensor."
echo ""
