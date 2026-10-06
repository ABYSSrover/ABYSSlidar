cmake_minimum_required(VERSION 3.10)
project(unitree_lidar_ros2)

if(POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

# Default to C99
if(NOT CMAKE_C_STANDARD)
  set(CMAKE_C_STANDARD 99)
endif()

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(pcl_conversions REQUIRED)
find_package(PCL REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(sensor_msgs REQUIRED)

include_directories(
  ${PCL_INCLUDE_DIRS} 
  include
  ../../../unitree_lidar_sdk/include
)

link_directories(
  ${PCL_LIBRARY_DIRS}
  ../../../unitree_lidar_sdk/lib/${CMAKE_SYSTEM_PROCESSOR}
)

add_definitions(${PCL_DEFINITIONS})

add_executable(unitree_lidar_ros2_node src/unitree_lidar_ros2_node.cpp)

target_link_libraries(unitree_lidar_ros2_node
  ${PCL_LIBRARIES}
  libunilidar_sdk2.a
  rclcpp::rclcpp
  ${std_msgs_TARGETS}
  ${sensor_msgs_TARGETS}
  ${geometry_msgs_TARGETS}
  tf2_ros::tf2_ros
  pcl_conversions::pcl_conversions
)

install(TARGETS
unitree_lidar_ros2_node
  DESTINATION lib/${PROJECT_NAME}
)

# install rviz file and launch file
install(FILES rviz/view.rviz launch/launch.py
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
