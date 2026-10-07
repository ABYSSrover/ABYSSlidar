# Running the LiDAR Software on your device
The LiDAR software is built to run on ROS2 on Linux. Here are the instructions to first install WSL(Your substitute for Linux), then install ROS and then finally install the LiDAR Software. Note: If youre feeling adventerous, you could go the windows installation route for ROS2, you may be able to bypass installing WSL but I haven't tried it and if you want to do it, thats on you to figure it out haha. If you want to try, jump to section 2 and follow the Winows Install link.

## 1. Installing Ubuntu 26.04 on your Windows 11 device
Here is a set of instructions on what Ubuntu is and how to install and use it through WSL. Note: I'm linking the official installation instructions websites so refer to those for debugging, I just thought I'd make your lives easier and compile everything in one place.

### 1.1 What is Ubuntu
Ubuntu is a Linux distro (A Linux operating system variant) and the operating system ABYSS will run. ABYSS will use the [ROS2 Lyrical Luth](https://docs.ros.org/en/lyrical/index.html) version of ROS2 (Robot Operating System) that is compatible with Windows 11 and Ubuntu 26.04. I (Cambri) use Ubuntu 26.04both through my dual boot and through WSL (Windows Subsystem for Linux) because I like it better. Some things in my instructions may work just fine with Windows 11 but I'm not doing any compatibility work to make sure it does. As I learn what requires Ubuntu and what doesn't I'll try and indicate as such.

### 1.2 Installing WSL
[WSL installation Official Page](https://ubuntu.com/wsl/docs/stable/howto/install-ubuntu-wsl2/)  

Open Windows PowerShell and enter
```
wsl --install
wsl --install Ubuntu-26.04
```
To access the terminal, search Ubuntu in the Windows search bar

## 2. Installing ROS2 (Lyrical)
Note: This allegedly works on windows but I haven't tested it. If you want to, follow these instructions: [Windows Install](https://docs.ros.org/en/lyrical/Get-Started/Installation/Windows-Install-Binary.html)

[Official ROS Installation Page(Linux)](https://docs.ros.org/en/lyrical/Get-Started/Installation/Ubuntu-Install-Debs.html)

### 2.1 Set up your system:
Make sure you have a locale which supports UTF-8. If you are in a minimal environment (such as a docker container), the locale may be something minimal like POSIX. We test with the following settings. However, it should be fine if you’re using a different UTF-8 supported locale.

```
locale  # check for UTF-8
sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
locale  # verify settings
```
Enable the required repositories:

```
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo apt update && sudo apt install curl -y
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb
sudo apt update && sudo apt install ros-dev-tools
```
### 2.2 Install ROS
```
sudo apt update
sudo apt upgrade
sudo apt install ros-lyrical-desktop
sudo apt install ros-lyrical-ros-base
```
### 2.3 Set up your environment
Note that every time you want to use ROS2, you have to activate it with this command:
```
source /opt/ros/lyrical/setup.bash
```

## 3. Installing the LiDAR Software with ROS2
[Unitree Documentation](../README.md)

### 3.1 Configuration

Before connecting the LiDAR, you need to change your IP Address to `192.168.1.2`. On Windows, you can do this in your network settings.

On Linux, create a connection using these commands:

```
sudo nmcli con add type ethernet ifname enp129s0 con-name unitree-lidar \
  ipv4.method manual ipv4.addresses 192.168.1.2/24 ipv4.gateway "" \
  autoconnect yes
sudo nmcli con up unitree-lidar
ip -4 addr show enp129s0
ping -c3 192.168.1.62 # Attempt to ping the LiDAR to verify if it worked.
```

The default communication method for the LiDAR is Ethernet mode. If you need to modify the working mode, you need to change the corresponding parameters in the configuration file. The path to the configuration file is:
```
unitree_lidar_ros2/src/unitree_lidar_ros2/launch/launch.py
```

If you have special needs, such as changing the cloud topic name or IMU topic name, you can also configure them in the configuration file.

The default cloud topic and its coordinate system name are:
- Topic name: "unilidar/cloud"
- Coordinate system: "unilidar_lidar"

The default IMU topic and its coordinate system name are:
- Topic name: "unilidar/imu"
- Coordinate system: "unilidar_imu"

### 3.2 Compilation

Compile:

```bash
cd unilidar_sdk/unitree_lidar_ros2

colcon build
```

### 3.3 Running

Run:

```bash
source install/setup.bash

ros2 launch unitree_lidar_ros2 launch.py
```

In the Rviz window, you will see our LiDAR point cloud as follows:

![img](./docs/ros2_cloud.png)

## 4. Installing the point lio

### 4.1 Install Dependencies:

```
sudo apt-get install -y ros-lyrical-pcl-ros
sudo apt-get install ros-lyrical-pcl-conversions
sudo apt-get install libeigen3-dev
```