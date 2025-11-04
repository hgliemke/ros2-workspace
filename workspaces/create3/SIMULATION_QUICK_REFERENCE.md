# Create3 Gazebo Simulation - Quick Reference Card

## Essential Commands

### Launch Simulation
```bash
# Basic launch
ros2 launch irobot_create_gz_bringup create3_gz.launch.py namespace:=putin world:=empty

# With dock
ros2 launch irobot_create_gz_bringup create3_gz.launch.py namespace:=putin world:=warehouse spawn_dock:=true
```

### Activate Controllers (REQUIRED!)
```bash
# Wait 15 seconds after launch, then:
ros2 control set_controller_state joint_state_broadcaster active --controller-manager /putin/controller_manager
ros2 control set_controller_state diffdrive_controller active --controller-manager /putin/controller_manager
```

### Check Controller Status
```bash
ros2 control list_controllers --controller-manager /putin/controller_manager
```

### Drive Robot - Keyboard Teleop
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r /cmd_vel:=/putin/cmd_vel_unstamped
```

### Drive Robot - Direct Commands
```bash
# Move forward
ros2 topic pub /putin/cmd_vel_unstamped geometry_msgs/msg/Twist "{linear: {x: 0.2}, angular: {z: 0.0}}" --rate 10

# Stop
ros2 topic pub --once /putin/cmd_vel_unstamped geometry_msgs/msg/Twist "{linear: {x: 0.0}, angular: {z: 0.0}}"
```

---

## Using Helper Scripts

### Quick Launch (All-in-One)
```bash
# Copy script to home directory first
chmod +x sim_launch.sh
./sim_launch.sh putin empty
```

### Controller Activation Script
```bash
chmod +x activate_controllers.sh
./activate_controllers.sh putin
```

### SLAM Testing
```bash
chmod +x sim_slam_launch.sh
./sim_slam_launch.sh putin warehouse
```

---

## Key Topics

| Topic | Message Type | Purpose |
|-------|--------------|---------|
| `/putin/cmd_vel` | TwistStamped | Gazebo GUI teleop |
| `/putin/cmd_vel_unstamped` | Twist | ROS2 teleop keyboard |
| `/putin/odom` | Odometry | Robot position |
| `/putin/tf` | TFMessage | Transforms |
| `/clock` | Clock | Simulation time |

---

## Troubleshooting

### Controllers Won't Activate
- Wait 20 seconds instead of 15
- Check if Gazebo is paused (click Play button)
- Restart Gazebo

### Robot Won't Move
- Check controllers: `ros2 control list_controllers --controller-manager /putin/controller_manager`
- Use correct topic: `/putin/cmd_vel_unstamped` for teleop_twist_keyboard
- Use correct topic: `/putin/cmd_vel` for Gazebo GUI teleop

### Timestamp Warnings
- Normal in simulation - usually still works
- Use `/putin/cmd_vel_unstamped` for teleop_twist_keyboard
- Increase timeout: `ros2 param set /putin/diffdrive_controller cmd_vel_timeout 10.0`

---

## Worlds Available

- `empty` - Just ground (fastest)
- `warehouse` - Simple warehouse
- `maze` - Maze environment  
- `depot` - Complex warehouse (slowest)

---

## Important Settings

### Always Set for Simulation
```bash
use_sim_time:=true
```

### Never Needed in Simulation
- TF relay scripts (only for real robot)
- Undock action (robot spawns undocked)

---

## Status Checks

```bash
# Check all topics
ros2 topic list | grep putin

# Check nodes
ros2 node list | grep putin

# Check transforms
ros2 run tf2_tools view_frames

# Monitor odometry
ros2 topic echo /putin/odom --once

# Check velocity commands
ros2 topic echo /putin/cmd_vel_unstamped
```

---

## Typical Workflow

1. Launch Gazebo → **wait 15 seconds**
2. Activate controllers → **verify both active**
3. Start teleop → **drive robot**
4. (Optional) Launch SLAM/Nav2
5. Done!

---

## Minimal Example

```bash
# Terminal 1
ros2 launch irobot_create_gz_bringup create3_gz.launch.py namespace:=putin world:=empty

# Wait 15 seconds, then Terminal 2
ros2 control set_controller_state joint_state_broadcaster active --controller-manager /putin/controller_manager
ros2 control set_controller_state diffdrive_controller active --controller-manager /putin/controller_manager

# Terminal 3
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r /cmd_vel:=/putin/cmd_vel_unstamped
```

---

## Remember

✅ Wait 15-20 seconds after Gazebo launch
✅ Activate controllers manually
✅ Use `/putin/cmd_vel_unstamped` for teleop_twist_keyboard
✅ Use `/putin/cmd_vel` for Gazebo GUI teleop
✅ Set `use_sim_time:=true` for all nodes
✅ No TF relays needed (unlike real robot)
✅ Robot spawns undocked (no undock action needed)

---

**Quick Help:** Full guide at SIMULATION_TESTING_GUIDE.md
