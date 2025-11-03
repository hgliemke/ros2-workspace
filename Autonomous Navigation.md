# Autonomous Navigation with Create3

This guide explains how to set up autonomous navigation for your Create3 robot to drive from the dock to multiple locations using Nav2.

---

## Prerequisites

1. Complete SLAM setup from `CREATE3_SLAM_SETUP.md`
2. Have a saved map of your environment
3. Nav2 packages installed

---

## Step 1: Install Nav2

```bash
sudo apt update
sudo apt install ros-jazzy-nav2-bringup ros-jazzy-navigation2
```

---

## Step 2: Create Navigation Launch File

Create a launch file for Nav2 with your robot namespace.

`~/ros2-workspace/src/create3_lidar_slam/launch/nav2_bringup.launch.py`:

```python
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():
    # Get package directories
    nav2_bringup_dir = get_package_share_directory('nav2_bringup')
    
    # Declare arguments
    use_sim_time = LaunchConfiguration('use_sim_time', default='false')
    map_yaml_file = LaunchConfiguration('map')
    params_file = LaunchConfiguration('params_file')
    
    # Include Nav2 bringup
    nav2_bringup = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(nav2_bringup_dir, 'launch', 'bringup_launch.py')
        ),
        launch_arguments={
            'use_sim_time': use_sim_time,
            'map': map_yaml_file,
            'params_file': params_file
        }.items()
    )
    
    return LaunchDescription([
        DeclareLaunchArgument(
            'use_sim_time',
            default_value='false',
            description='Use simulation clock'),
        
        DeclareLaunchArgument(
            'map',
            default_value=os.path.expanduser('~/maps/my_map.yaml'),
            description='Full path to map yaml file'),
        
        DeclareLaunchArgument(
            'params_file',
            default_value=os.path.join(
                get_package_share_directory('create3_lidar_slam'),
                'config', 'nav2_params.yaml'),
            description='Full path to Nav2 parameters file'),
        
        nav2_bringup
    ])
```

---

## Step 3: Create Nav2 Parameters File

Create `~/ros2-workspace/src/create3_lidar_slam/config/nav2_params.yaml`:

```yaml
bt_navigator:
  ros__parameters:
    use_sim_time: false
    global_frame: map
    robot_base_frame: base_link
    odom_topic: /putin/odom
    bt_loop_duration: 10
    default_server_timeout: 20

controller_server:
  ros__parameters:
    use_sim_time: false
    controller_frequency: 20.0
    min_x_velocity_threshold: 0.001
    min_y_velocity_threshold: 0.5
    min_theta_velocity_threshold: 0.001
    progress_checker_plugin: "progress_checker"
    goal_checker_plugins: ["general_goal_checker"]
    controller_plugins: ["FollowPath"]
    
    progress_checker:
      plugin: "nav2_controller::SimpleProgressChecker"
      required_movement_radius: 0.5
      movement_time_allowance: 10.0
    
    general_goal_checker:
      stateful: True
      plugin: "nav2_controller::SimpleGoalChecker"
      xy_goal_tolerance: 0.25
      yaw_goal_tolerance: 0.25
    
    FollowPath:
      plugin: "dwb_core::DWBLocalPlanner"
      min_vel_x: 0.0
      min_vel_y: 0.0
      max_vel_x: 0.26
      max_vel_y: 0.0
      max_vel_theta: 1.0
      min_speed_xy: 0.0
      max_speed_xy: 0.26
      min_speed_theta: 0.0
      acc_lim_x: 2.5
      acc_lim_y: 0.0
      acc_lim_theta: 3.2
      decel_lim_x: -2.5
      decel_lim_y: 0.0
      decel_lim_theta: -3.2
      vx_samples: 20
      vy_samples: 5
      vtheta_samples: 20
      sim_time: 1.7
      linear_granularity: 0.05
      angular_granularity: 0.025
      transform_tolerance: 0.2
      xy_goal_tolerance: 0.25
      trans_stopped_velocity: 0.25
      short_circuit_trajectory_evaluation: True
      stateful: True
      critics: ["RotateToGoal", "Oscillation", "BaseObstacle", "GoalAlign", "PathAlign", "PathDist", "GoalDist"]
      BaseObstacle.scale: 0.02
      PathAlign.scale: 32.0
      PathAlign.forward_point_distance: 0.1
      GoalAlign.scale: 24.0
      GoalAlign.forward_point_distance: 0.1
      PathDist.scale: 32.0
      GoalDist.scale: 24.0
      RotateToGoal.scale: 32.0
      RotateToGoal.slowing_factor: 5.0
      RotateToGoal.lookahead_time: -1.0

local_costmap:
  local_costmap:
    ros__parameters:
      update_frequency: 5.0
      publish_frequency: 2.0
      global_frame: odom
      robot_base_frame: base_link
      use_sim_time: false
      rolling_window: true
      width: 3
      height: 3
      resolution: 0.05
      robot_radius: 0.22
      plugins: ["obstacle_layer", "inflation_layer"]
      inflation_layer:
        plugin: "nav2_costmap_2d::InflationLayer"
        cost_scaling_factor: 3.0
        inflation_radius: 0.55
      obstacle_layer:
        plugin: "nav2_costmap_2d::ObstacleLayer"
        enabled: True
        observation_sources: scan
        scan:
          topic: /putin/scan
          max_obstacle_height: 2.0
          clearing: True
          marking: True
          data_type: "LaserScan"

global_costmap:
  global_costmap:
    ros__parameters:
      update_frequency: 1.0
      publish_frequency: 1.0
      global_frame: map
      robot_base_frame: base_link
      use_sim_time: false
      robot_radius: 0.22
      resolution: 0.05
      track_unknown_space: true
      plugins: ["static_layer", "obstacle_layer", "inflation_layer"]
      obstacle_layer:
        plugin: "nav2_costmap_2d::ObstacleLayer"
        enabled: True
        observation_sources: scan
        scan:
          topic: /putin/scan
          max_obstacle_height: 2.0
          clearing: True
          marking: True
          data_type: "LaserScan"
      static_layer:
        plugin: "nav2_costmap_2d::StaticLayer"
        map_subscribe_transient_local: True
      inflation_layer:
        plugin: "nav2_costmap_2d::InflationLayer"
        cost_scaling_factor: 3.0
        inflation_radius: 0.55

planner_server:
  ros__parameters:
    expected_planner_frequency: 20.0
    use_sim_time: false
    planner_plugins: ["GridBased"]
    GridBased:
      plugin: "nav2_navfn_planner/NavfnPlanner"
      tolerance: 0.5
      use_astar: false
      allow_unknown: true

smoother_server:
  ros__parameters:
    use_sim_time: false
    smoother_plugins: ["simple_smoother"]
    simple_smoother:
      plugin: "nav2_smoother::SimpleSmoother"
      tolerance: 1.0e-10
      max_its: 1000
      do_refinement: True

behavior_server:
  ros__parameters:
    costmap_topic: local_costmap/costmap_raw
    footprint_topic: local_costmap/published_footprint
    cycle_frequency: 10.0
    behavior_plugins: ["spin", "backup", "wait"]
    spin:
      plugin: "nav2_behaviors/Spin"
    backup:
      plugin: "nav2_behaviors/BackUp"
    wait:
      plugin: "nav2_behaviors/Wait"
    global_frame: odom
    robot_base_frame: base_link
    transform_tolerance: 0.1
    use_sim_time: false
    simulate_ahead_time: 2.0
    max_rotational_vel: 1.0
    min_rotational_vel: 0.4
    rotational_acc_lim: 3.2

waypoint_follower:
  ros__parameters:
    use_sim_time: false
    loop_rate: 20
    stop_on_failure: false
    waypoint_task_executor_plugin: "wait_at_waypoint"
    wait_at_waypoint:
      plugin: "nav2_waypoint_follower::WaitAtWaypoint"
      enabled: True
      waypoint_pause_duration: 200
```

---

## Step 4: Python Navigation Program

Create `~/autonomous_nav.py`:

```python
#!/usr/bin/env python3
"""
Autonomous Navigation Program for Create3
Drives from dock to multiple waypoints using Nav2
"""

import rclpy
from rclpy.node import Node
from rclpy.action import ActionClient
from nav2_msgs.action import NavigateToPose
from geometry_msgs.msg import PoseStamped
from action_msgs.msg import GoalStatus
from irobot_create_msgs.action import Undock
import time

class AutonomousNavigator(Node):
    def __init__(self):
        super().__init__('autonomous_navigator')
        
        # Create action clients
        self.nav_client = ActionClient(self, NavigateToPose, 'navigate_to_pose')
        self.undock_client = ActionClient(self, Undock, '/putin/undock')
        
        self.get_logger().info('Autonomous Navigator initialized')
        
    def undock_robot(self):
        """Undock the robot from charging station"""
        self.get_logger().info('Undocking robot...')
        
        if not self.undock_client.wait_for_server(timeout_sec=5.0):
            self.get_logger().error('Undock action server not available')
            return False
        
        goal = Undock.Goal()
        future = self.undock_client.send_goal_async(goal)
        
        rclpy.spin_until_future_complete(self, future)
        goal_handle = future.result()
        
        if not goal_handle.accepted:
            self.get_logger().error('Undock goal rejected')
            return False
        
        self.get_logger().info('Undocking...')
        result_future = goal_handle.get_result_async()
        rclpy.spin_until_future_complete(self, result_future)
        
        if result_future.result().status == GoalStatus.STATUS_SUCCEEDED:
            self.get_logger().info('Successfully undocked!')
            return True
        else:
            self.get_logger().error('Failed to undock')
            return False
    
    def create_pose(self, x, y, theta):
        """Create a PoseStamped message"""
        pose = PoseStamped()
        pose.header.frame_id = 'map'
        pose.header.stamp = self.get_clock().now().to_msg()
        
        pose.pose.position.x = x
        pose.pose.position.y = y
        pose.pose.position.z = 0.0
        
        # Convert theta to quaternion
        import math
        pose.pose.orientation.z = math.sin(theta / 2.0)
        pose.pose.orientation.w = math.cos(theta / 2.0)
        
        return pose
    
    def navigate_to_pose(self, x, y, theta):
        """Navigate to a specific pose"""
        self.get_logger().info(f'Navigating to: x={x:.2f}, y={y:.2f}, theta={theta:.2f}')
        
        if not self.nav_client.wait_for_server(timeout_sec=5.0):
            self.get_logger().error('Nav2 action server not available')
            return False
        
        # Create navigation goal
        goal_msg = NavigateToPose.Goal()
        goal_msg.pose = self.create_pose(x, y, theta)
        
        # Send goal
        send_goal_future = self.nav_client.send_goal_async(goal_msg)
        rclpy.spin_until_future_complete(self, send_goal_future)
        goal_handle = send_goal_future.result()
        
        if not goal_handle.accepted:
            self.get_logger().error('Navigation goal rejected')
            return False
        
        self.get_logger().info('Navigation goal accepted, robot moving...')
        
        # Wait for result
        result_future = goal_handle.get_result_async()
        rclpy.spin_until_future_complete(self, result_future)
        
        status = result_future.result().status
        if status == GoalStatus.STATUS_SUCCEEDED:
            self.get_logger().info('Successfully reached goal!')
            return True
        else:
            self.get_logger().error(f'Navigation failed with status: {status}')
            return False
    
    def run_mission(self, waypoints):
        """Execute a mission with multiple waypoints"""
        # Step 1: Undock
        if not self.undock_robot():
            self.get_logger().error('Mission aborted: Could not undock')
            return
        
        # Wait a moment after undocking
        time.sleep(2.0)
        
        # Step 2: Navigate to each waypoint
        for i, (x, y, theta) in enumerate(waypoints):
            self.get_logger().info(f'Going to waypoint {i+1}/{len(waypoints)}')
            
            if not self.navigate_to_pose(x, y, theta):
                self.get_logger().error(f'Failed to reach waypoint {i+1}, aborting mission')
                return
            
            # Pause at waypoint
            self.get_logger().info(f'Reached waypoint {i+1}, pausing...')
            time.sleep(3.0)
        
        self.get_logger().info('Mission completed successfully!')

def main(args=None):
    rclpy.init(args=args)
    
    navigator = AutonomousNavigator()
    
    # Define waypoints: (x, y, theta)
    # Replace these with your actual waypoint coordinates
    waypoints = [
        (1.0, 0.5, 0.0),      # Waypoint 1
        (2.0, 1.0, 1.57),     # Waypoint 2 (facing 90 degrees)
        (1.5, 2.0, 3.14),     # Waypoint 3 (facing 180 degrees)
        (0.0, 0.0, 0.0),      # Return to origin
    ]
    
    try:
        navigator.run_mission(waypoints)
    except KeyboardInterrupt:
        navigator.get_logger().info('Mission interrupted by user')
    finally:
        navigator.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
```

Make it executable:
```bash
chmod +x ~/autonomous_nav.py
```

---

## Step 5: How to Get Waypoint Coordinates

### Method 1: Using RViz (Easiest)

1. Launch RViz with your map loaded
2. Click "2D Pose Estimate" and click locations on the map
3. Watch the terminal output or use:
   ```bash
   ros2 topic echo /clicked_point
   ```
4. Record the x, y coordinates and orientation

### Method 2: Using Current Robot Position

```bash
# Get current robot position
ros2 topic echo /putin/odom --once
```

Drive the robot to each location you want and record the x, y coordinates.

### Method 3: Programmatically Save Waypoints

Create a waypoint recorder:

```python
#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from nav_msgs.msg import Odometry
import json

class WaypointRecorder(Node):
    def __init__(self):
        super().__init__('waypoint_recorder')
        self.waypoints = []
        self.subscription = self.create_subscription(
            Odometry, '/putin/odom', self.odom_callback, 10)
        self.get_logger().info('Waypoint Recorder started. Drive robot and press Enter to save waypoint.')
        
    def odom_callback(self, msg):
        self.current_pose = msg.pose.pose
    
    def save_waypoint(self):
        if hasattr(self, 'current_pose'):
            x = self.current_pose.position.x
            y = self.current_pose.position.y
            # Extract yaw from quaternion
            import math
            qz = self.current_pose.orientation.z
            qw = self.current_pose.orientation.w
            theta = 2.0 * math.atan2(qz, qw)
            
            self.waypoints.append({'x': x, 'y': y, 'theta': theta})
            self.get_logger().info(f'Saved waypoint: x={x:.2f}, y={y:.2f}, theta={theta:.2f}')
            return True
        return False
    
    def save_to_file(self, filename='waypoints.json'):
        with open(filename, 'w') as f:
            json.dump(self.waypoints, f, indent=2)
        self.get_logger().info(f'Saved {len(self.waypoints)} waypoints to {filename}')

def main():
    rclpy.init()
    recorder = WaypointRecorder()
    
    import threading
    def spin_thread():
        rclpy.spin(recorder)
    
    thread = threading.Thread(target=spin_thread, daemon=True)
    thread.start()
    
    try:
        while True:
            input("Press Enter to save current position as waypoint (Ctrl+C to finish)...")
            recorder.save_waypoint()
    except KeyboardInterrupt:
        recorder.save_to_file()
        print("\nWaypoints saved!")
    finally:
        recorder.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
```

---

## Step 6: Running Autonomous Navigation

### Terminal Setup:

**Terminal 1 (SBC): TF Relays**
```bash
python3 ~/tf_relay.py &
python3 ~/tf_static_relay.py &
```

**Terminal 2 (SBC): SLAM (optional if you already have a map)**
```bash
# Skip if using localization mode with existing map
```

**Terminal 3: Nav2**
```bash
cd ~/ros2-workspace
source install/setup.bash
colcon build --packages-select create3_lidar_slam
source install/setup.bash

ros2 launch create3_lidar_slam nav2_bringup.launch.py map:=~/maps/my_map.yaml
```

**Terminal 4: Run Navigation Program**
```bash
python3 ~/autonomous_nav.py
```

---

## Tips and Best Practices

1. **Test Navigation Manually First:**
   - Use RViz's "2D Nav Goal" tool to test navigation before running autonomous code
   
2. **Start with Simple Missions:**
   - Test with 2-3 waypoints first
   - Gradually increase complexity

3. **Safety:**
   - Always supervise the robot
   - Have emergency stop ready (Ctrl+C or physical button)
   - Test in open space first

4. **Tuning:**
   - Adjust velocity limits in `nav2_params.yaml` for your environment
   - Modify `robot_radius` if the robot is too cautious or reckless
   - Tune `inflation_radius` for obstacle avoidance

5. **Debugging:**
   ```bash
   # Monitor navigation status
   ros2 topic echo /navigate_to_pose/_action/status
   
   # View costmaps in RViz
   # Add display: Map -> /global_costmap/costmap
   # Add display: Map -> /local_costmap/costmap
   ```

---

## Common Issues

### Robot won't start navigating:
- Check Nav2 is running: `ros2 node list | grep nav`
- Verify map is loaded: `ros2 topic echo /map --once`
- Check localization: `ros2 topic echo /amcl_pose`

### Robot gets stuck:
- Increase `inflation_radius` to give more clearance
- Lower max velocities if moving too fast
- Check costmaps in RViz for obstacles

### Navigation fails frequently:
- Improve map quality (remap environment)
- Tune controller parameters
- Check TF transforms are continuous

---

## Next Steps

1. Add more sophisticated behaviors (e.g., docking after mission)
2. Implement obstacle avoidance strategies
3. Add mission scheduling
4. Integrate with higher-level task planning
5. Add visual feedback (LED patterns, sounds)

---

## Resources

- [Nav2 Documentation](https://navigation.ros.org/)
- [Create3 Documentation](https://iroboteducation.github.io/create3_docs/)
- [ROS2 Actions Tutorial](https://docs.ros.org/en/jazzy/Tutorials/Intermediate/Writing-an-Action-Server-Client/Py.html)
