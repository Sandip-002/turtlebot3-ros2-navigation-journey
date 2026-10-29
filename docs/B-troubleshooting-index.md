# Appendix B: Troubleshooting index

Find your symptom, check the likely cause, and jump to the chapter that explains it.

> **How reliable is each row?** Rows marked **(happened to me)** are problems I really hit and
> solved while building this guide. The others are **general guidance** from the chapters: they are
> well-known causes, but I did not have to fix them on my own robot.

**Contents:** [Debug in this order](#debug-in-this-order) ·
[Pi and network](#1-the-pi-and-the-network) · [ROS commands and Docker](#2-ros-commands-and-docker) ·
[The two machines](#3-the-robot-and-the-pc-cannot-see-each-other) · [Driving](#4-driving-the-robot) ·
[Transforms and time](#5-transforms-and-time) · [Mapping](#6-mapping-and-saving-the-map) ·
[Nav2](#7-navigation-with-nav2) · [Power](#8-power) ·
[Scary but harmless](#messages-that-look-scary-but-are-fine) · [Asking for help](#what-to-collect-before-asking-for-help)

---

## Debug in this order

Problems at a lower layer cause confusing symptoms in the layers above. Check from the bottom up:

| # | Layer | Quick check | Chapter |
|---|-------|-------------|---------|
| 1 | **Power** | Battery voltage, no beeping, no under-voltage warnings | [13](13-wobbly-navigation-and-the-preflight-checklist.md) |
| 2 | **Network** | `ping` the Pi from the PC and the PC from the Pi | [02](02-getting-the-pi-online.md), [05](05-two-machines-one-ros-graph.md) |
| 3 | **Clocks** | `date` on both machines | [08](08-no-transform-and-the-clock.md), [09](09-time-sync-without-internet.md) |
| 4 | **ROS graph** | `ros2 node list` and `ros2 topic list` from the container | [05](05-two-machines-one-ros-graph.md) |
| 5 | **Transforms** | `ros2 run tf2_ros tf2_monitor` | [08](08-no-transform-and-the-clock.md) |
| 6 | **The application** | RViz, Cartographer or Nav2 behaviour | [10](10-mapping-with-cartographer.md), [12](12-navigating-with-nav2.md) |

The clock problem in this guide looked like a network problem and cost real time. **Check `date`
before blaming the wifi.**

---

## 1. The Pi and the network

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| The default TurtleBot3 login does not work **(happened to me)** | A used robot: the password was changed | Ask the previous user for it | [01](01-inspecting-a-used-robot.md) |
| The Pi does not join your wifi **(happened to me)** | Mistake in the netplan file (typo, tabs instead of spaces, wrong interface name), a 5 GHz-only network on a 2.4 GHz-only Pi, or a second netplan file that also defines `wlan0` | `sudo netplan generate`, then `sudo netplan try` | [02](02-getting-the-pi-online.md) |
| `ssh` rejects the **correct** password **(happened to me)** | You typed `ssh <PI_IP>` without `ubuntu@`, so SSH used your PC username | `ssh ubuntu@<PI_IP>` | [02](02-getting-the-pi-online.md) |
| SSH to the Pi no longer reaches it after a reboot **(happened to me)** | The router gave the Pi a new IP address | `ip -br a` on the Pi (monitor), then use the new address. Make a DHCP reservation | [02](02-getting-the-pi-online.md) |
| `apt` cannot download on the Pi | The lab router has no internet | Add a phone hotspot as a second network | [02](02-getting-the-pi-online.md), [01](01-inspecting-a-used-robot.md) |

## 2. ROS commands and Docker

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| `ros2: command not found` | ROS is not loaded in this terminal | `source /opt/ros/humble/setup.bash` | [01](01-inspecting-a-used-robot.md), [03](03-docker-on-the-pc.md) |
| `Package 'turtlebot3_teleop' not found` in the container **(happened to me)** | The base image has ROS but not the TurtleBot3 packages | Install them in a container that keeps its changes | [03](03-docker-on-the-pc.md) |
| `docker` says permission denied | Your user is not in the `docker` group | `sudo usermod -aG docker $USER`, then log out and back in | [03](03-docker-on-the-pc.md) |
| `docker ps -a` shows `Exited (137)` | The container was killed, usually at PC shutdown | `docker start <name>`. Nothing is lost | [03](03-docker-on-the-pc.md) |
| Docker says the container name is already in use | The container already exists | Use `docker start` and `docker exec`, not `docker run` | [07](07-rviz-inside-docker.md) |
| A long `docker run` command fails **(happened to me)** | A typo, such as a missing space in `--network host` or a stray space in a path | Check each part against the option table | [07](07-rviz-inside-docker.md) |
| A package you installed in the container is gone | The container was started with `--rm` or was deleted | Use a named container without `--rm` | [03](03-docker-on-the-pc.md) |
| A GUI window will not open from the container | The display permission was not granted, or `DISPLAY` is missing | `xhost +local:docker` on the PC (I had to repeat it in new sessions) **(happened to me)** | [07](07-rviz-inside-docker.md) |

## 3. The robot and the PC cannot see each other

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| The container shows only `/parameter_events` and `/rosout` | Different domain ID, `ROS_LOCALHOST_ONLY=1`, container not on the host network, different networks, or a firewall | `printenv \| grep -E "ROS\|RMW"` on both, `ping` both ways, `--network host` | [05](05-two-machines-one-ros-graph.md) |
| Old nodes stay listed after you stop the robot software | Cached node list | `ros2 daemon stop` | [05](05-two-machines-one-ros-graph.md) |
| Topics are listed but no data arrives | Network trouble, or a QoS mismatch | `ros2 topic hz <topic>`, `ros2 topic info <topic> -v` | [05](05-two-machines-one-ros-graph.md), [A](A-concept-cheat-sheet.md#quality-of-service-qos) |
| The Pi's `/tf` rate matches the PC's rate, but RViz still complains **(happened to me)** | The data arrives fine, so the cause is not packet loss: look at the clocks | `date` on both machines | [08](08-no-transform-and-the-clock.md) |

## 4. Driving the robot

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| The robot keeps driving after you stop pressing a key | In teleop, the keys **change the speed**: the robot keeps going until you press `s` | Press `s` or the space bar | [06](06-driving-the-robot.md) |
| Teleop keys do nothing | The teleop window is not selected | Click the terminal running teleop | [06](06-driving-the-robot.md) |
| Only one wheel turns, or they turn the wrong way | Motor or cable trouble | Wheels lifted, `w` then `a`/`d`, check the motor cables | [06](06-driving-the-robot.md) |
| `[XMLPARSER Error] realpath failed ...` **(happened to me)** | Harmless: the DDS library did not find an optional configuration file | Does the topic still work? Then ignore it | [06](06-driving-the-robot.md) |

## 5. Transforms and time

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| RViz shows `No transform from [frame] to [map]` for every robot frame **(happened to me)** | The Pi and the PC disagree about the time. (It also appears when nothing publishes `map → odom`, such as Cartographer not running) | `date` on both, then `tf2_monitor` | [08](08-no-transform-and-the-clock.md) |
| `tf2_monitor` shows an average delay of millions of seconds for **every** frame **(happened to me)** | One cause: the Pi's clock is months off | `date` on the Pi | [08](08-no-transform-and-the-clock.md) |
| The clock is still off by tens of seconds after you set it by hand **(happened to me)** | The time you spent typing the password was baked into the command | Run a time server on the PC instead | [09](09-time-sync-without-internet.md) |
| Clocks agree, then disagree again after a reboot | The Pi has no battery-backed clock and starts wrong | `timedatectl timesync-status` before starting bringup | [09](09-time-sync-without-internet.md) |
| Clocks disagree after the Pi changed network **(happened to me)** | Time sync did not pick up the new network | `sudo systemctl restart systemd-timesyncd` | [09](09-time-sync-without-internet.md) |
| The PC's time server is no longer used | The PC's IP address changed | Update `NTP=` on the Pi, or reserve the PC's address | [09](09-time-sync-without-internet.md) |

## 6. Mapping and saving the map

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| The map does not grow | No scan data is reaching Cartographer | `ros2 topic hz /scan` in the container | [10](10-mapping-with-cartographer.md) |
| Walls appear twice or smeared | Driving or turning too fast, or wheels slipping | Slow down, and drive a loop | [10](10-mapping-with-cartographer.md) |
| The map breaks up in a long, plain corridor | Too few features for scan matching | Drive past furniture or doorways | [10](10-mapping-with-cartographer.md) |
| The RViz laser display shows nothing, but `/scan` has data | A QoS mismatch is one possible cause. I did not verify this on my robot | Set the display's Reliability Policy to *Best Effort* | [A](A-concept-cheat-sheet.md#quality-of-service-qos) |
| `map_saver_cli` fails with "Failed to spin map subscription" (or similar) | There is no `/map` topic: Cartographer is not running | Save the map **before** stopping Cartographer | [11](11-saving-the-map.md) |
| The saved map is gone | It was only inside a deleted container | `docker cp` it out | [11](11-saving-the-map.md) |
| Nav2 cannot load the map | The yaml's `image:` line does not match the `.pgm`, or the files are in different folders | `cat` the yaml, `ls` the folder | [11](11-saving-the-map.md) |

## 7. Navigation with Nav2

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| The lidar dots do not line up with the map's walls | Wrong initial pose | Click *2D Pose Estimate* again, using the walls to place it | [12](12-navigating-with-nav2.md) |
| The green particle cloud stays wide | Not enough movement, or the robot is in an open area | Rotate in place near a wall, then check the covariance | [12](12-navigating-with-nav2.md) |
| The robot ignores a goal | The goal is in unknown or blocked space, or the robot is not localised | Pick a goal in clear white space | [12](12-navigating-with-nav2.md) |
| Transform warnings or odd jumps right after launching Nav2 | Cartographer is still running too | Stop it: both publish `map → odom` | [12](12-navigating-with-nav2.md) |
| The local costmap square looks tilted | Normal: it is aligned with `odom`, not `map` | Nothing to fix | [12](12-navigating-with-nav2.md) |
| Wobbling, refusing long goals, or failing to turn around for a goal behind it **(happened to me; cause not proven)** | Suspects: weak battery, clock out of sync, stale state, network lag | The toolkit and baseline in Chapter 13, then the reset ritual | [13](13-wobbly-navigation-and-the-preflight-checklist.md) |

## 8. Power

| Symptom | Likely cause | First check | Chapter |
|---------|--------------|-------------|---------|
| `Undervoltage detected!` on the Pi console **(happened to me)** | The Pi is not getting enough power at that moment | `vcgencmd get_throttled`, `sudo dmesg \| grep -i undervoltage`, battery voltage | [13](13-wobbly-navigation-and-the-preflight-checklist.md), Appendix D |
| The OpenCR board beeps | Low battery voltage | Recharge | [13](13-wobbly-navigation-and-the-preflight-checklist.md) |

---

## Messages that look scary but are fine

| Message or value | Why it is harmless | Chapter |
|------------------|--------------------|---------|
| `[XMLPARSER Error] realpath failed No such file or directory` | The DDS library looks for an optional config file | [06](06-driving-the-robot.md) |
| `Free threshold unspecified` and `Occupied threshold unspecified` when saving a map | The tool is using its default thresholds | [11](11-saving-the-map.md) |
| `published by <no authority available>` in `tf2_monitor` | A quirk of the tool's output | [08](08-no-transform-and-the-clock.md) |
| A "delay" of around 3000 s for static frames in `tf2_monitor` | It is the age of a transform published once at startup | [09](09-time-sync-without-internet.md) |
| A small **negative** TF delay (about -0.04 s) | The sender's clock is a hair ahead. That is fine | [09](09-time-sync-without-internet.md) |
| `/transform_listener_impl_...` in the node list | Hidden helper nodes created by programs that listen to TF | [10](10-mapping-with-cartographer.md) |
| `Exited (137)` in `docker ps -a` | The container was killed, not crashed | [03](03-docker-on-the-pc.md) |
| A tilted local costmap square in RViz | It follows the `odom` frame | [12](12-navigating-with-nav2.md) |

---

## What to collect before asking for help

If you ask on a forum or in an issue, people can help much faster with this information:

```bash
# [Pi]
lsb_release -d
dpkg -l | grep ros-humble-turtlebot3 | awk '{print $2, $3}'
date +%T.%N
timedatectl timesync-status
```

```bash
# [PC]
lsb_release -d
docker --version
date +%T.%N
```

```bash
# [PC-container]
printenv | grep -E "ROS|RMW"
ros2 node list
ros2 topic list -t
ros2 run tf2_ros tf2_monitor
```

Also say:

1. **What you expected**, and **what happened instead**, with the exact error text.
2. **What changed** since it last worked. (One change at a time, as in Chapter 13.)
3. **What you already tried**.

**Remove passwords, wifi keys and personal details** from anything you post.
