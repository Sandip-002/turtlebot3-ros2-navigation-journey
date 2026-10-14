# Chapter 00: Before you start

> **Command tags:** `[Pi]` = SSH session on the robot, `[PC]` = normal PC terminal,
> `[PC-container]` = inside the Docker container on the PC.

## Goal

Know what you need, which versions this guide was written against, how to stay safe around
a moving robot, and how the rest of the chapters are laid out.

## ROS concepts in this chapter

Only one, but it matters for everything that follows.

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **ROS 2 distribution** | A named release of ROS 2 (for example *Humble* or *Jazzy*). Each one is built for a specific Ubuntu version: Humble for Ubuntu 22.04, Jazzy for Ubuntu 24.04. | `printenv ROS_DISTRO` (after sourcing a ROS setup file) |

In this project the robot's Pi runs **Humble** and the PC's own Ubuntu is a newer version that
pairs with **Jazzy**. Mixing distributions on different machines is not officially supported,
so Chapter 03 solves that by running Humble on the PC as well, inside Docker.

## What you need

| Item | Notes |
|------|-------|
| TurtleBot3 Waffle Pi | OpenCR control board, LDS-01 lidar, Raspberry Pi 3 |
| Power for the robot | Battery pack and/or a 12 V adapter plugged into the OpenCR |
| A PC | Ubuntu with permission to install Docker (this guide used Ubuntu 24.04) |
| A wifi router | Both the Pi and the PC must be on the same network. The router does **not** need internet, but see Chapter 09 for the clock problem that causes |
| Monitor, keyboard, HDMI cable | Only for the Pi's first login and wifi setup (Chapter 01 and 02) |
| Open floor space | A room or corridor with no stairs or drops; mapping works best where there are walls and furniture to see |

## Versions used in this guide

| Part | Version |
|------|---------|
| Robot OS | Ubuntu 22.04.5 LTS (aarch64) |
| Robot ROS | ROS 2 Humble |
| TurtleBot3 packages on the Pi | 2.3.6 (`turtlebot3_msgs` is 2.4.0, which is normal) |
| Lidar | LDS-01 |
| PC OS | Ubuntu 24.04.4 LTS |
| Docker | 29.8.2 |
| Base container image | `osrf/ros:humble-desktop` |

If your versions differ, most steps still work, but check the package names and launch
files against your own install (Chapter 01 shows how).

## Safety

- **First tests with the wheels off the ground.** Lift the robot, or put it on a box, until you
  have seen the wheels respond correctly to commands.
- **Know three ways to stop it.** Press `s` in the teleop terminal, press `Ctrl+C` in the terminal
  running the launch file, and switch off the OpenCR power switch.
- **Stay next to the robot** for the first autonomous runs. Keep your hand near the keyboard.
- **Respect the battery.** Charge it before a session, do not leave it charging unattended, and
  stop if it beeps (low voltage alarm). Chapter 13 and Appendix D explain why a weak battery
  can look like a software problem.
- **Mind the table edge.** The lidar only sees at its own height, so the robot will drive off
  a ledge it cannot see.

## Conventions used in every chapter

- **Command tags:** every code block starts with a comment saying where to run it.
- **Placeholders:** `<PI_IP>`, `<PC_IP>`, `<USER>`. Replace them with your own values.
  Never put real passwords or wifi keys in notes or screenshots you share.
- **ROS environment:** in any new terminal where you run `ros2`, load the ROS setup file first:

  ```bash
  # [Pi] or [PC-container]
  source /opt/ros/humble/setup.bash
  export TURTLEBOT3_MODEL=waffle_pi
  ```

  `TURTLEBOT3_MODEL` tells the TurtleBot3 packages which robot variant to load
  (this guide uses `waffle_pi`).
- **Checklists:** each chapter ends with a short checklist. Do not move on until it is ticked.

## Checklist

- [ ] You have all items from the table above
- [ ] You know which Ubuntu and ROS versions you will be working with
- [ ] You know the three ways to stop the robot
- [ ] You understand the `[Pi]`, `[PC]` and `[PC-container]` tags

## Recap

- You collected the hardware and checked the versions this guide assumes.
- You met your first ROS idea: the distribution, and why matching it on both machines matters.
- Next: find out what is already installed on a second-hand robot, before installing anything.
