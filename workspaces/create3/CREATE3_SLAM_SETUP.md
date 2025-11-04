# Create3 SLAM Setup with Namespace

This guide documents the modifications needed to run SLAM Toolbox with a namespaced iRobot Create3 robot.

## Problem

When using the Create3 with a namespace (e.g., `putin`), the SLAM Toolbox from `create3_lidar_slam` package fails because:
1. All Create3 topics are namespaced: `/putin/scan`, `/putin/tf`, `/putin/tf_static`
2. SLAM Toolbox expects global topics: `/scan`, `/tf`, `/tf_static`
3. The TF frames themselves are NOT namespaced (they're just `odom`, `base_footprint`, `laser_frame`)

## Solution Overview

The solution involves creating relay nodes that bridge the namespaced topics to global topics that SLAM expects.

---

## Required Modifications

### 1. TF Relay Scripts

Create two Python scripts to relay TF data from namespaced to global topics.

#### `~/tf_relay.py`

```python
#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from tf2_msgs.msg import TFMessage

class TFRelay(Node):
    def __init__(self):
        super().__init__('tf_relay')
        self.subscription = self.create_subscription(
            TFMessage, '/putin/tf', self.tf_callback, 10)
        self.publisher = self.create_publisher(TFMessage, '/tf', 10)
        self.get_logger().info('TF relay started: /putin/tf -> /tf')

    def tf_callback(self, msg):
        self.publisher.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = TFRelay()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

#### `~/tf_static_relay.py`

```python
#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, DurabilityPolicy
from tf2_msgs.msg import TFMessage

class TFStaticRelay(Node):
    def __init__(self):
        super().__init__('tf_static_relay')
        
        # QoS for tf_static (transient local)
        qos = QoSProfile(depth=10, durability=DurabilityPolicy.TRANSIENT_LOCAL)
        
        self.subscription = self.create_subscription(
            TFMessage, '/putin/tf_static', self.callback, qos)
        self.publisher = self.create_publisher(TFMessage, '/tf_static', qos)
        self.get_logger().info('TF static relay: /putin/tf_static -> /tf_static')

    def callback(self, msg):
        self.publisher.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = TFStaticRelay()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

**Make them executable:**
```bash
chmod +x ~/tf_relay.py ~/tf_static_relay.py
```

---

## Launch Sequence

Follow this order to start everything:

### On the SBC (Single Board Computer attached to Create3):

**Terminal 1: TF Relay**
```bash
python3 ~/tf_relay.py
```

**Terminal 2: TF Static Relay**
```bash
python3 ~/tf_static_relay.py
```

**Terminal 3: SLAM Toolbox**
```bash
cd ~/ros2-workspace
source install/setup.bash

# Start SLAM
ros2 run slam_toolbox async_slam_toolbox_node \
  --ros-args \
  --params-file $(ros2 pkg prefix create3_lidar_slam)/share/create3_lidar_slam/config/mapper_params_online_async.yaml \
  -p scan_topic:=/putin/scan

# In another terminal, activate the lifecycle node
ros2 lifecycle set /slam_toolbox configure
ros2 lifecycle set /slam_toolbox activate
```

### On your Desktop/Laptop:

**Terminal 1: RViz with TF remapping**
```bash
rviz2 --ros-args -r /tf:=/putin/tf -r /tf_static:=/putin/tf_static
```

In RViz:
1. Set **Fixed Frame** to `map`
2. Add **Map** display (topic: `/map`)
3. Add **LaserScan** display (topic: `/putin/scan`)
4. Add **TF** display (optional)
5. Add **RobotModel** (optional)

**Terminal 2: Teleop (for initial mapping)**
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -r /cmd_vel:=/putin/cmd_vel
```

---

## Verification

Check that everything is working:

```bash
# Check scan data
ros2 topic hz /putin/scan  # Should show ~7-8 Hz

# Check map is being published
ros2 topic hz /map  # Should show ~1 Hz

# Check TF chain
ros2 run tf2_ros tf2_echo map odom  # Should show transform data

# Check SLAM is subscribed correctly
ros2 node info /slam_toolbox | grep "/putin/scan"
```

---

## Important Topics and Frames

### Topics:
- `/putin/scan` - Laser scan data from RPLidar
- `/putin/cmd_vel` - Velocity commands to robot
- `/putin/odom` - Odometry from robot
- `/putin/tf` - Dynamic transforms from robot
- `/putin/tf_static` - Static transforms from robot
- `/map` - Occupancy grid map from SLAM
- `/tf` - Global TF (relayed from `/putin/tf`)
- `/tf_static` - Global static TF (relayed from `/putin/tf_static`)

### TF Frames:
- `map` - SLAM's global map frame
- `odom` - Robot's odometry frame
- `base_footprint` - Robot's base on ground
- `base_link` - Robot's center
- `laser_frame` - RPLidar sensor frame

---

## Saving the Map

Once you've mapped your environment:

```bash
# Save the map
ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph "{filename: '/home/hgl/maps/my_map'}"
```

Or use map_server:
```bash
ros2 run nav2_map_server map_saver_cli -f ~/maps/my_map
```

---

## Troubleshooting

### SLAM not processing scans:
- Check: `ros2 topic hz /slam_toolbox/scan_visualization`
- If no messages, verify TF relays are running
- Check: `ros2 run tf2_ros tf2_echo odom base_footprint`

### Map frame doesn't exist:
- Drive the robot around for 20-30 seconds to initialize SLAM
- SLAM needs motion to establish the map frame

### RViz doesn't show frames:
- Ensure RViz was launched with TF remapping: `--ros-args -r /tf:=/putin/tf -r /tf_static:=/putin/tf_static`

### QoS warnings on tf_static:
- Ensure `tf_static_relay.py` uses `TRANSIENT_LOCAL` durability policy

---

## Next Steps: Autonomous Navigation

To enable autonomous navigation from dock to multiple locations:

1. **Install Nav2** (ROS2 Navigation Stack)
2. **Create a saved map** using the procedure above
3. **Configure Nav2** for Create3
4. **Write navigation program** using Nav2 action client

See `AUTONOMOUS_NAVIGATION.md` for detailed instructions.

---

## Robot Configuration

- **Robot Name/Namespace:** `putin`
- **Lidar:** RPLidar A1
- **ROS2 Distribution:** Jazzy Jalisco
- **Workspace:** `~/ros2-workspace`
- **SLAM Package:** `create3_lidar_slam`

---

## File Locations

- TF Relay Scripts: `~/tf_relay.py`, `~/tf_static_relay.py`
- Workspace: `~/ros2-workspace`
- SLAM Config: `~/ros2-workspace/src/create3_lidar_slam/config/mapper_params_online_async.yaml`
- Maps (suggested): `~/maps/`

---

## Notes

- The namespace approach (launching everything under `/putin/`) doesn't work properly with SLAM Toolbox in Jazzy
- The relay approach is a workaround that bridges namespaced Create3 topics to global SLAM topics
- TF frames themselves are NOT namespaced - they're global (e.g., `odom`, not `putin/odom`)
- This is a known limitation when mixing namespaced robots with packages that expect global topics
