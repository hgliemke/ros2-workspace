# Navigation2 Workspace

## System Dependencies
```bash
sudo apt install libceres-dev libxsimd-dev libxtensor-dev \
  libnanoflann-dev libompl-dev libgeographiclib-dev
```

## Setup
```bash
cd ~/ros2/navigate
vcs import src < navigate.repos
source /opt/ros/jazzy/setup.bash
colcon build --symlink-install --parallel-workers 1 \
  --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
```

## Usage
```bash
source ~/ros2/navigate/install/setup.bash
```
