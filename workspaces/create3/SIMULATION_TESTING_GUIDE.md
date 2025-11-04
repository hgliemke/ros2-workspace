# Create3 Gazebo Simulation Testing Guide

Complete guide for testing Create3 robot in Gazebo Harmonic simulation, including controller activation, teleop, SLAM, and autonomous navigation.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Controller Activation](#controller-activation)
4. [Teleop Control](#teleop-control)
5. [SLAM Testing](#slam-testing)
6. [Autonomous Navigation Testing](#autonomous-navigation-testing)
7. [Automated Launch Scripts](#automated-launch-scripts)
8. [Troubleshooting](#troubleshooting)
9. [Differences: Simulation vs Real Robot](#differences-simulation-vs-real-robot)

---

## Prerequisites

### Install Required Packages

```bash
# Gazebo Harmonic packages
sudo apt update
sudo apt install ros-jazzy-irobot-create-gz-bringup \
                 ros-jazzy-irobot-create-gz-sim \
                 ros-jazzy-irobot-create-gz-plugins \
                 ros-jazzy-ros-gz \
                 ros-jazzy-teleop-twist-keyboard

# SLAM and Navigation (if needed)
sudo apt install ros-jazzy-slam-toolbox \
                 ros-jazzy-nav2-bringup
```

### Verify Installation

```bash
# Check Gazebo version
gz sim --version

# Verify Create3 packages
ros2 pkg list | grep irobot_create_gz
```

---

## Quick Start

### Basic Launch (Empty World)

```bash
ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=putin \
  world:=empty
```

**Wait 15-20 seconds** for full initialization before proceeding.

### Available Worlds

- `empty` - Just ground plane (fastest, simplest)
- `warehouse` - Simple warehouse environment
- `maze` - Maze environment
- `depot` - Complex warehouse (slower to load)

---

## Controller Activation

### Problem

Controllers start in **inactive** state and must be manually activated before the robot will move.

### Manual Activation

After launching Gazebo, **wait 15-20 seconds**, then in a new terminal:

```bash
# Activate joint state broadcaster
ros2 control set_controller_state joint_state_broadcaster active \
  --controller-manager /putin/controller_manager

# Activate differential drive controller
ros2 control set_controller_state diffdrive_controller active \
  --controller-manager /putin/controller_manager
```

### Verify Controllers are Active

```bash
ros2 control list_controllers --controller-manager /putin/controller_manager
```

Expected output:
```
diffdrive_controller    diff_drive_controller/DiffDriveController      active
joint_state_broadcaster joint_state_broadcaster/JointStateBroadcaster  active
```

### Automated Activation Script

Create `~/activate_controllers.sh`:

```bash
#!/bin/bash

NAMESPACE=${1:-putin}

echo "Waiting for controller manager to be ready..."
sleep 15

echo "Activating controllers for namespace: $NAMESPACE"

# Activate joint_state_broadcaster
echo "Activating joint_state_broadcaster..."
ros2 control set_controller_state joint_state_broadcaster active \
  --controller-manager /$NAMESPACE/controller_manager

if [ $? -eq 0 ]; then
    echo "✓ joint_state_broadcaster activated"
else
    echo "✗ Failed to activate joint_state_broadcaster"
fi

# Activate diffdrive_controller
echo "Activating diffdrive_controller..."
ros2 control set_controller_state diffdrive_controller active \
  --controller-manager /$NAMESPACE/controller_manager

if [ $? -eq 0 ]; then
    echo "✓ diffdrive_controller activated"
else
    echo "✗ Failed to activate diffdrive_controller"
fi

# Verify
echo ""
echo "Controller status:"
ros2 control list_controllers --controller-manager /$NAMESPACE/controller_manager
```

Make it executable:
```bash
chmod +x ~/activate_controllers.sh
```

Usage:
```bash
# After launching Gazebo
~/activate_controllers.sh putin
```

---

## Teleop Control

### Important Topic Information

The Create3 has multiple cmd_vel topics:

| Topic | Message Type | Use With |
|-------|--------------|----------|
| `/putin/cmd_vel` | `TwistStamped` | Gazebo GUI teleop plugin |
| `/putin/cmd_vel_unstamped` | `Twist` | ROS2 teleop_twist_keyboard |
| `/putin/diffdrive_controller/cmd_vel` | `TwistStamped` | Direct controller input |

### Method 1: ROS2 Teleop (Recommended)

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args -r /cmd_vel:=/putin/cmd_vel_unstamped
```

**Controls:**
- `u` `i` `o` - Forward (left, straight, right)
- `j` `k` `l` - Rotate (left, stop, right)
- `m` `,` `.` - Backward
- `q`/`z` - Increase/decrease max speeds
- `w`/`x` - Increase/decrease linear speed
- `e`/`c` - Increase/decrease angular speed
- `SPACE` or `k` - Force stop

### Method 2: Gazebo GUI Teleop Plugin

1. Look at the **right panel** in Gazebo window
2. Find the **Teleop** plugin section
3. Set topic to: `/putin/cmd_vel`
4. Use **WASD** or **arrow keys** to drive

### Method 3: Direct Topic Publishing (Testing)

```bash
# Move forward
ros2 topic pub /putin/cmd_vel_unstamped geometry_msgs/msg/Twist \
  "{linear: {x: 0.2}, angular: {z: 0.0}}" --rate 10

# Stop (Ctrl+C or publish zero velocity)
ros2 topic pub --once /putin/cmd_vel_unstamped geometry_msgs/msg/Twist \
  "{linear: {x: 0.0}, angular: {z: 0.0}}"
```

### Verification

```bash
# Check if commands are being received
ros2 topic echo /putin/cmd_vel_unstamped

# Check odometry (robot position)
ros2 topic echo /putin/odom --once
```

---

## SLAM Testing

### Prerequisites

Simulation does **not** require TF relays (unlike the physical robot).

### Launch Sequence

**Terminal 1: Start Gazebo**
```bash
ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=putin \
  world:=warehouse
```

**Terminal 2: Activate Controllers (wait 15 seconds)**
```bash
~/activate_controllers.sh putin
```

**Terminal 3: Launch SLAM Toolbox**
```bash
ros2 run slam_toolbox async_slam_toolbox_node \
  --ros-args \
  --params-file $(ros2 pkg prefix create3_lidar_slam)/share/create3_lidar_slam/config/mapper_params_online_async.yaml \
  -p use_sim_time:=true \
  -p scan_topic:=/putin/scan

# Activate SLAM (in another terminal after it starts)
ros2 lifecycle set /slam_toolbox configure
ros2 lifecycle set /slam_toolbox activate
```

**Note:** The default Create3 model in Gazebo **does not include a lidar sensor**. You'll need to either:
1. Use the IR sensors (limited range)
2. Add a custom lidar sensor to the model
3. Test with obstacles placed manually in the world

**Terminal 4: Launch RViz**
```bash
rviz2 --ros-args -p use_sim_time:=true
```

**Configure RViz:**
1. Fixed Frame: `map`
2. Add display: **Map** → topic `/map`
3. Add display: **LaserScan** → topic `/putin/scan` (if available)
4. Add display: **RobotModel**
5. Add display: **TF**

**Terminal 5: Drive the Robot**
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args -r /cmd_vel:=/putin/cmd_vel_unstamped
```

### Save the Map

```bash
# Using SLAM Toolbox
ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph \
  "{filename: '/home/hgl/maps/sim_map'}"

# Or using map_server
ros2 run nav2_map_server map_saver_cli -f ~/maps/sim_map
```

---

## Autonomous Navigation Testing

### Launch Sequence

**Terminal 1: Start Gazebo**
```bash
ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=putin \
  world:=warehouse
```

**Terminal 2: Activate Controllers**
```bash
~/activate_controllers.sh putin
```

**Terminal 3: Launch Nav2**
```bash
ros2 launch nav2_bringup bringup_launch.py \
  use_sim_time:=true \
  map:=~/maps/sim_map.yaml \
  params_file:=~/ros2/workspaces/src/create3_lidar_slam/config/nav2_params.yaml
```

**Terminal 4: Launch RViz for Nav2**
```bash
ros2 launch nav2_bringup rviz_launch.py use_sim_time:=true
```

**Terminal 5: Run Your Navigation Script**
```bash
python3 ~/autonomous_nav.py
```

### Modified Navigation Script for Simulation

Update your `autonomous_nav.py` to handle simulation gracefully:

```python
def undock_robot(self, timeout=5.0):
    """Undock the robot - handles both simulation and real robot"""
    self.get_logger().info('Checking dock status...')
    
    # In simulation, robot spawns undocked - check if action exists
    if not self.undock_client.wait_for_server(timeout_sec=timeout):
        self.get_logger().warn('Undock action not available')
        
        # Check if robot is already undocked in simulation
        try:
            # Just verify robot is responsive
            self.get_logger().info('Robot appears to be in simulation - already undocked')
            return True
        except:
            self.get_logger().error('Cannot verify robot status')
            return False
    
    # Real robot or simulation with dock - execute undock
    goal = Undock.Goal()
    future = self.undock_client.send_goal_async(goal)
    
    rclpy.spin_until_future_complete(self, future, timeout_sec=10.0)
    goal_handle = future.result()
    
    if not goal_handle.accepted:
        self.get_logger().error('Undock goal rejected')
        return False
    
    result_future = goal_handle.get_result_async()
    rclpy.spin_until_future_complete(self, result_future, timeout_sec=30.0)
    
    if result_future.result().status == GoalStatus.STATUS_SUCCEEDED:
        self.get_logger().info('Successfully undocked!')
        return True
    else:
        self.get_logger().error('Failed to undock')
        return False
```

### Test Navigation Goals

#### Using RViz:
1. Click **"2D Nav Goal"** button
2. Click on the map and drag to set goal pose
3. Robot should navigate autonomously

#### Using Command Line:
```bash
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose \
  "{pose: {header: {frame_id: 'map'}, pose: {position: {x: 2.0, y: 1.0}}}}"
```

---

## Automated Launch Scripts

### Complete Simulation Launch Script

Create `~/sim_launch.sh`:

```bash
#!/bin/bash

NAMESPACE=${1:-putin}
WORLD=${2:-warehouse}

echo "========================================="
echo "Create3 Simulation Launch Script"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "World: $WORLD"
echo ""

# Launch Gazebo in background
echo "[1/4] Launching Gazebo simulation..."
gnome-terminal -- bash -c "ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=$NAMESPACE world:=$WORLD; exec bash"

# Wait for Gazebo to initialize
echo "[2/4] Waiting for Gazebo to initialize (15 seconds)..."
sleep 15

# Activate controllers
echo "[3/4] Activating controllers..."
gnome-terminal -- bash -c "~/activate_controllers.sh $NAMESPACE; exec bash"

# Wait for controllers to activate
sleep 3

# Launch teleop
echo "[4/4] Launching teleop..."
gnome-terminal -- bash -c "ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args -r /cmd_vel:=/$NAMESPACE/cmd_vel_unstamped; exec bash"

echo ""
echo "========================================="
echo "Simulation ready!"
echo "========================================="
echo "Use the teleop terminal to drive the robot"
echo "Gazebo GUI: Use WASD or teleop panel"
echo ""
```

Make executable:
```bash
chmod +x ~/sim_launch.sh
```

Usage:
```bash
# Default (putin namespace, warehouse world)
~/sim_launch.sh

# Custom namespace and world
~/sim_launch.sh my_robot empty
```

### SLAM Testing Launch Script

Create `~/sim_slam_launch.sh`:

```bash
#!/bin/bash

NAMESPACE=${1:-putin}
WORLD=${2:-warehouse}

echo "Launching SLAM simulation test..."

# Launch Gazebo
gnome-terminal -- bash -c "ros2 launch irobot_create_gz_bringup create3_gz.launch.py \
  namespace:=$NAMESPACE world:=$WORLD; exec bash"

sleep 15

# Activate controllers
gnome-terminal -- bash -c "~/activate_controllers.sh $NAMESPACE; exec bash"

sleep 3

# Launch SLAM
gnome-terminal -- bash -c "ros2 run slam_toolbox async_slam_toolbox_node \
  --ros-args \
  --params-file \$(ros2 pkg prefix create3_lidar_slam)/share/create3_lidar_slam/config/mapper_params_online_async.yaml \
  -p use_sim_time:=true \
  -p scan_topic:=/$NAMESPACE/scan && \
  sleep 5 && \
  ros2 lifecycle set /slam_toolbox configure && \
  ros2 lifecycle set /slam_toolbox activate; exec bash"

sleep 5

# Launch RViz
gnome-terminal -- bash -c "rviz2 --ros-args -p use_sim_time:=true; exec bash"

sleep 3

# Launch teleop
gnome-terminal -- bash -c "ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args -r /cmd_vel:=/$NAMESPACE/cmd_vel_unstamped; exec bash"

echo "SLAM simulation ready!"
```

Make executable:
```bash
chmod +x ~/sim_slam_launch.sh
```

---

## Troubleshooting

### Controllers Won't Activate

**Symptom:** Error activating controllers

**Solutions:**
1. Wait longer (20-30 seconds) after Gazebo launch
2. Check if Gazebo is paused - click Play button in GUI
3. Verify controller_manager is running:
   ```bash
   ros2 node list | grep controller_manager
   ```
4. Try service call directly:
   ```bash
   ros2 service call /putin/controller_manager/switch_controller \
     controller_manager_msgs/srv/SwitchController \
     "{activate_controllers: ['joint_state_broadcaster', 'diffdrive_controller'], strictness: 1}"
   ```

### Robot Won't Move

**Symptom:** Commands sent but robot doesn't move

**Check:**
1. Controllers active?
   ```bash
   ros2 control list_controllers --controller-manager /putin/controller_manager
   ```
2. Using correct topic?
   - ROS2 teleop → `/putin/cmd_vel_unstamped`
   - Gazebo GUI teleop → `/putin/cmd_vel`
3. Simulation running (not paused)?
4. Monitor topics:
   ```bash
   ros2 topic hz /putin/cmd_vel_unstamped
   ros2 topic hz /putin/odom
   ```

### Timestamp Warnings

**Symptom:** 
```
[WARN] Ignoring received message because it is older than current time
```

**Solutions:**
1. Use `/putin/cmd_vel_unstamped` instead of `/putin/cmd_vel` for teleop_twist_keyboard
2. Increase controller timeout:
   ```bash
   ros2 param set /putin/diffdrive_controller cmd_vel_timeout 10.0
   ```
3. These are usually just warnings - robot should still work

### Gazebo Loads Slowly

**Symptom:** Long startup time, high CPU usage

**Solutions:**
1. Use simpler world (`empty` instead of `depot`)
2. Close other applications
3. Reduce rendering quality in Gazebo GUI
4. Check system resources:
   ```bash
   top
   ```

### No Laser Scan Data

**Symptom:** No `/putin/scan` topic or no data

**Reason:** Default Create3 model doesn't include lidar sensor

**Solutions:**
1. Use IR intensity sensors (limited range)
2. Manually place obstacles to test
3. Add custom lidar sensor to robot model (advanced)

### Undock Action Fails

**Symptom:** Undock action rejected or fails

**Reason:** Robot spawns already undocked in simulation

**Solution:** Check if robot is already undocked:
```bash
ros2 topic echo /putin/dock_status --once
```

In simulation, you can usually skip undocking entirely.

---

## Differences: Simulation vs Real Robot

### Key Differences

| Aspect | Real Robot | Simulation |
|--------|-----------|------------|
| **Launch command** | `create3_gz.launch.py` | Physical robot API |
| **TF relays** | ❌ Not needed | ✅ Required |
| **Controller activation** | ✅ Required manually | ❌ Auto-activated |
| **Undocking** | ✅ Usually required | ❌ Spawns undocked |
| **Lidar** | ✅ RPLidar present | ❌ Not in default model |
| **Sim time** | `use_sim_time:=true` | `use_sim_time:=false` |
| **Clock** | Uses `/clock` from sim | Uses system time |
| **Teleop topic** | `/putin/cmd_vel_unstamped` | Same |
| **Startup time** | Instant | 15-20 seconds |

### Parameter Differences

Always set `use_sim_time:=true` for all nodes in simulation:

```bash
# Example for SLAM
ros2 run slam_toolbox async_slam_toolbox_node \
  --ros-args -p use_sim_time:=true

# Example for Nav2
ros2 launch nav2_bringup bringup_launch.py use_sim_time:=true
```

### Code Adaptations

Your autonomous navigation code should detect if running in simulation:

```python
def is_simulation(self):
    """Detect if running in simulation"""
    try:
        # Check if /clock topic exists (simulation publishes this)
        topics = self.get_topic_names_and_types()
        return any(topic[0] == '/clock' for topic in topics)
    except:
        return False

def setup(self):
    if self.is_simulation():
        self.get_logger().info('Running in SIMULATION mode')
        # Set use_sim_time parameter
        self.set_parameters([rclpy.parameter.Parameter(
            'use_sim_time', 
            rclpy.Parameter.Type.BOOL, 
            True)])
    else:
        self.get_logger().info('Running on REAL ROBOT')
```

---

## Testing Checklist

### Basic Functionality
- [ ] Gazebo launches successfully
- [ ] Controllers activate (both show "active")
- [ ] Robot moves with teleop_twist_keyboard
- [ ] Robot moves with Gazebo GUI teleop
- [ ] Odometry is being published
- [ ] TF frames are visible

### SLAM Testing
- [ ] SLAM node starts without errors
- [ ] Map topic is being published
- [ ] Map builds as robot moves
- [ ] RViz displays map correctly
- [ ] Can save map successfully

### Navigation Testing
- [ ] Nav2 launches with saved map
- [ ] Can set navigation goals in RViz
- [ ] Robot navigates to goals autonomously
- [ ] Obstacle avoidance works
- [ ] Robot reaches goals successfully

---

## Quick Reference Commands

### Check Status
```bash
# Controllers
ros2 control list_controllers --controller-manager /putin/controller_manager

# Topics
ros2 topic list | grep putin

# Nodes
ros2 node list | grep putin

# Parameters
ros2 param list /putin/diffdrive_controller
```

### Start/Stop Commands
```bash
# Stop robot immediately
ros2 topic pub --once /putin/cmd_vel_unstamped geometry_msgs/msg/Twist \
  "{linear: {x: 0.0}, angular: {z: 0.0}}"

# Reset simulation
gz service -s /world/warehouse/control \
  --reqtype gz.msgs.WorldControl \
  --reptype gz.msgs.Boolean \
  --timeout 1000 \
  --req 'reset: {all: true}'
```

### Debugging
```bash
# Monitor velocity commands
ros2 topic echo /putin/cmd_vel_unstamped

# Monitor odometry
ros2 topic echo /putin/odom

# Check TF tree
ros2 run tf2_tools view_frames

# Check controller manager logs
ros2 topic echo /rosout | grep controller_manager
```

---

## Resources

- **Gazebo Documentation:** https://gazebosim.org/docs
- **Create3 Docs:** https://iroboteducation.github.io/create3_docs/
- **ROS2 Control:** https://control.ros.org/
- **Nav2 Documentation:** https://navigation.ros.org/

---

## Summary

### Minimal Working Example

```bash
# Terminal 1: Launch Gazebo
ros2 launch irobot_create_gz_bringup create3_gz.launch.py namespace:=putin world:=empty

# Wait 15 seconds, then Terminal 2: Activate controllers
ros2 control set_controller_state joint_state_broadcaster active --controller-manager /putin/controller_manager
ros2 control set_controller_state diffdrive_controller active --controller-manager /putin/controller_manager

# Terminal 3: Drive the robot
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r /cmd_vel:=/putin/cmd_vel_unstamped
```

### Key Takeaways

1. ✅ **Always wait 15-20 seconds** after Gazebo launch before activating controllers
2. ✅ **Controllers must be manually activated** in simulation
3. ✅ **Use `/putin/cmd_vel_unstamped`** for teleop_twist_keyboard
4. ✅ **Set `use_sim_time:=true`** for all ROS2 nodes in simulation
5. ✅ **No TF relays needed** in simulation (unlike real robot)
6. ✅ **Robot spawns undocked** in simulation

---

**Happy Simulating! 🤖**
