# Create3 ROS2 Workspace

ROS2 Jazzy workspace for iRobot Create3 robot with SLAM and autonomous navigation.

## Documentation

- [CREATE3_SLAM_SETUP.md](CREATE3_SLAM_SETUP.md) - SLAM setup with namespace workarounds
- [AUTONOMOUS_NAVIGATION.md](AUTONOMOUS_NAVIGATION.md) - Nav2 autonomous navigation guide
- [SIMULATION_TESTING_GUIDE.md](SIMULATION_TESTING_GUIDE.md) - Complete Gazebo simulation guide
- [SIMULATION_QUICK_REFERENCE.md](SIMULATION_QUICK_REFERENCE.md) - Quick command reference

## Helper Scripts

- `activate_controllers.sh` - Activate controllers in Gazebo simulation
- `sim_launch.sh` - Launch complete simulation with teleop
- `sim_slam_launch.sh` - Launch simulation with SLAM
- `tf_relay.py` - TF relay for physical robot
- `tf_static_relay.py` - Static TF relay for physical robot

## Quick Start - Simulation
```bash
./sim_launch.sh putin empty
```

## Quick Start - Physical Robot

See [CREATE3_SLAM_SETUP.md](CREATE3_SLAM_SETUP.md)
