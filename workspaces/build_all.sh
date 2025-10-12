#!/bin/bash

# Build all workspaces in correct order
WORKSPACES=("base" "create3" "turtlebot3" "sensors" "control")

echo "Updating rosdep database..."
rosdep update

for ws in "${WORKSPACES[@]}"; do
    echo "========================================"
    echo "Building $ws workspace..."
    echo "========================================"
    cd ~/ros2/workspaces/$ws
    
    # Check if src directory exists and has content
    if [ ! -d "src" ] || [ -z "$(ls -A src)" ]; then
        echo "⚠ $ws/src is empty, skipping..."
        continue
    fi
    
    # Install dependencies (skip if fails - some packages might not be available)
    echo "Installing dependencies for $ws..."
    rosdep install --from-paths src --ignore-src -r -y || echo "⚠ Some dependencies could not be installed, continuing..."
    
    # Build with tests disabled
    if [ "$ws" = "base" ]; then
        # Special handling for base workspace
        colcon build --symlink-install \
            --allow-overriding rmw_fastrtps_cpp \
            --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
    else
        colcon build --symlink-install \
            --cmake-args -DCMAKE_BUILD_TYPE=Release
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ $ws built successfully"
    else
        echo "✗ $ws build failed!"
        echo "Continue anyway? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    echo ""
done

echo "========================================"
echo "Build process complete!"
echo "Run 'source ~/.bashrc' to update environment"
echo "========================================"
