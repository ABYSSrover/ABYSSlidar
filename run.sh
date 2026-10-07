#!/usr/bin/env bash
# Sources ROS2 and both workspaces, then runs the Unitree LiDAR driver
# and Point-LIO together. Ctrl+C stops both.
#
# Only one driver may run at a time: the LiDAR streams to UDP port 6201, and a
# second instance silently fails to bind and then spams
# "[WARNING] Unilidar is not initialized!" while publishing nothing. Both
# instances still advertise /unilidar/cloud, so Point-LIO can end up fed by the
# wrong one. This script refuses to start a duplicate.
#
#   ./run.sh            start the driver and Point-LIO
#   ./run.sh --reuse    a driver is already running; start only Point-LIO
#   ./run.sh --restart  kill any running driver/Point-LIO first, then start
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_WS="$REPO_ROOT/unitree_lidar_ros2"
POINT_LIO_WS="$REPO_ROOT/point_lio_ros2_ws"
DRIVER_BIN="lib/unitree_lidar_ros2/unitree_lidar_ros2_node"
POINT_LIO_BIN="lib/point_lio/pointlio_mapping"

MODE="start"
case "${1:-}" in
  --reuse) MODE="reuse" ;;
  --restart) MODE="restart" ;;
  "") ;;
  *) echo "Unknown option: $1 (expected --reuse or --restart)" >&2; exit 1 ;;
esac

# pgrep -f matches on command line, which also hits this script and any shell
# whose arguments happen to contain the pattern. Confirm each candidate by
# resolving /proc/<pid>/exe to the real executable.
running_pids() {
  local pat="$1" pid exe out=""
  for pid in $(pgrep -f "$pat" 2>/dev/null); do
    [ "$pid" = "$$" ] && continue
    exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
    case "$exe" in *"$pat") out="$out $pid" ;; esac
  done
  echo "${out# }"
}

for ws_install in "$DRIVER_WS/install" "$POINT_LIO_WS/install"; do
  if [ ! -f "$ws_install/setup.bash" ]; then
    echo "Missing $ws_install/setup.bash - run colcon build in $(dirname "$ws_install") first." >&2
    exit 1
  fi
done

if [ "$MODE" = "restart" ]; then
  for pat in "$DRIVER_BIN" "$POINT_LIO_BIN"; do
    pids="$(running_pids "$pat")"
    [ -n "$pids" ] && echo "Stopping existing: $pids" && kill -9 $pids 2>/dev/null || true
  done
  sleep 2
fi

EXISTING_DRIVER="$(running_pids "$DRIVER_BIN")"
if [ -n "$EXISTING_DRIVER" ] && [ "$MODE" != "reuse" ]; then
  echo "A LiDAR driver is already running (PID: $EXISTING_DRIVER)." >&2
  echo "Starting a second one would fail to bind UDP port 6201 and publish nothing." >&2
  echo "Use './run.sh --reuse' to start only Point-LIO, or './run.sh --restart' to replace it." >&2
  exit 1
fi

EXISTING_LIO="$(running_pids "$POINT_LIO_BIN")"
if [ -n "$EXISTING_LIO" ]; then
  echo "Point-LIO is already running (PID: $EXISTING_LIO). Use './run.sh --restart'." >&2
  exit 1
fi

source /opt/ros/lyrical/setup.bash
source "$DRIVER_WS/install/setup.bash"
source "$POINT_LIO_WS/install/setup.bash"

DRIVER_PID=""
cleanup() {
  if [ -n "$DRIVER_PID" ] && kill -0 "$DRIVER_PID" 2>/dev/null; then
    kill "$DRIVER_PID" 2>/dev/null
    wait "$DRIVER_PID" 2>/dev/null
  fi
}
trap cleanup EXIT INT TERM

if [ "$MODE" = "reuse" ]; then
  echo "Reusing existing driver (PID: ${EXISTING_DRIVER:-none})."
else
  ros2 launch unitree_lidar_ros2 launch.py &
  DRIVER_PID=$!
  # Give the SDK time to bind the UDP port and start receiving before Point-LIO
  # begins consuming scans.
  sleep 3
  if ! kill -0 "$DRIVER_PID" 2>/dev/null; then
    echo "Driver exited during startup - check the LiDAR connection (ping 192.168.1.62)." >&2
    exit 1
  fi
fi

ros2 launch point_lio mapping_unilidar_l2.launch.py
