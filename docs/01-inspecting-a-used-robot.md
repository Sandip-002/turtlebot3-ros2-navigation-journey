# Chapter 01: Inspecting a used robot

> **Command tags:** `[Pi]` = SSH session on the robot (or the Pi's own keyboard and monitor),
> `[PC]` = normal PC terminal, `[PC-container]` = inside the Docker container on the PC.

## Goal

Find out what operating system, ROS version and TurtleBot3 packages are **already** on a
second-hand Pi, so you do not reinstall things that work or install things that clash.

## ROS concepts in this chapter

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **ROS 2 distribution** | The robot's Pi has *Humble* installed under `/opt/ros/humble` | `ls /opt/ros` |
| **Package** | A bundle of ROS code installed with apt, named `ros-humble-<name>` | `dpkg -l \| grep ros-humble-turtlebot3` |
| **Metapackage** | A package that only pulls in other packages. `ros-humble-turtlebot3` installs the whole TurtleBot3 set | `apt-cache depends ros-humble-turtlebot3` |
| **Environment sourcing** | Running `source /opt/ros/humble/setup.bash` makes the `ros2` command and the installed packages visible to your terminal | `printenv ROS_DISTRO` before and after sourcing |

Why sourcing matters: a fresh terminal does not know where ROS is. If `ros2` says
*command not found*, you almost always just forgot to source the setup file.

## Before you start

- [ ] Chapter 00 checklist is done
- [ ] Robot powered on, Pi booted
- [ ] A monitor and keyboard connected to the Pi (SSH comes in Chapter 02)

## Steps

### Step 1.1: Log in to the Pi

Log in on the Pi's own keyboard and monitor. The documented default TurtleBot3
credentials may **not** work on a used robot (see [When it broke](#when-it-broke)).

### Step 1.2: Check the operating system

```bash
# [Pi]
lsb_release -d
uname -m
```

**You should see** (this is what my robot showed):

```text
Description:	Ubuntu 22.04.5 LTS
aarch64
```

Ubuntu 22.04 is the release that ROS 2 Humble is built for.

### Step 1.3: Check whether ROS is installed

```bash
# [Pi]
ls /opt/ros
source /opt/ros/humble/setup.bash
printenv ROS_DISTRO
```

**You should see:** `humble` listed under `/opt/ros`, and `humble` printed by `printenv`.

### Step 1.4: Check which TurtleBot3 packages are installed

```bash
# [Pi]
dpkg -l | grep ros-humble-turtlebot3 | awk '{print $2, $3}'
```

**You should see** (my robot):

```text
ros-humble-turtlebot3 2.3.6-1jammy.20260427.084116
ros-humble-turtlebot3-bringup 2.3.6-1jammy.20260427.081636
ros-humble-turtlebot3-cartographer 2.3.6-1jammy.20260426.044739
ros-humble-turtlebot3-description 2.3.6-1jammy.20260329.212816
ros-humble-turtlebot3-example 2.3.6-1jammy.20260422.225211
ros-humble-turtlebot3-msgs 2.4.0-1jammy.20260416.054553
ros-humble-turtlebot3-navigation2 2.3.6-1jammy.20260427.083223
ros-humble-turtlebot3-node 2.3.6-1jammy.20260423.173154
ros-humble-turtlebot3-teleop 2.3.6-1jammy.20260422.225211
```

What each package is for:

| Package | Role in this guide |
|---------|--------------------|
| `turtlebot3_bringup` | Starts the robot's drivers (Chapter 04) |
| `turtlebot3_node` | The node that talks to the OpenCR board and motors |
| `turtlebot3_teleop` | Drive the robot with the keyboard (Chapter 06) |
| `turtlebot3_cartographer` | Mapping (Chapter 10) |
| `turtlebot3_navigation2` | Nav2 settings for this robot (Chapter 12) |
| `turtlebot3_description` | The robot's 3D model and frame layout |
| `turtlebot3_msgs` | Custom message types |
| `turtlebot3_example` | Demo programs (not used here) |

The same list also tells you everything is already there, so there is nothing to install on the Pi.

### Step 1.5: Watch the console for warnings

While you are logged in on the Pi's own screen, look at the messages that scroll past.
On my robot this line repeated:

```text
hwmon hwmon1: Undervoltage detected!
```

This means the Pi is not getting enough power at that moment. It did not stop the software
checks, but it is a real hardware warning. I noted it and carried on; the full story is in
[Appendix D](D-power-and-undervoltage.md).

### Step 1.6: Make a decision

Putting the findings together:

- The Pi already runs a complete **Humble** setup, so there is no need to reflash it.
- My PC's own Ubuntu pairs with **Jazzy**, and different distributions on different machines
  is not officially supported.
- **Decision:** keep the Pi as it is, and run **Humble inside Docker on the PC** so both ends
  use the same distribution (Chapter 03).

## Checklist

- [ ] You are logged in to the Pi
- [ ] You know the Pi's Ubuntu version and CPU type (`aarch64` here)
- [ ] `ros2` works after sourcing, and `printenv ROS_DISTRO` prints `humble`
- [ ] You have a list of installed TurtleBot3 packages and their versions
- [ ] You noted any warnings on the console
- [ ] You can explain why sourcing `setup.bash` is needed in every new terminal

## When it broke

| | |
|---|---|
| **Symptom** | The documented default TurtleBot3 login did not work on the Pi |
| **What I thought it was** | A mistake in the username or password I was typing |
| **How I tested it** | Tried again carefully with the documented default credentials |
| **What it really was** | The robot is second-hand and its password had been changed |
| **Fix** | I asked my supervisor for the correct password and logged in |
| **Lesson** | On a used robot, ask the previous user for the credentials **before** trying to guess or reflash. If nobody knows them, the fallback is to write a fresh image to the SD card, but that costs you the existing setup, so it is the last option |

## Recap

- You inspected the robot instead of assuming what was on it.
- You met four ROS ideas: distribution, package, metapackage and environment sourcing.
- You made a plan: keep the Pi on Humble, and use Docker on the PC.
- Next: put the Pi on your wifi and log in over SSH, so you can drop the monitor and keyboard.

## Try it yourself (optional)

Run `apt-cache depends ros-humble-turtlebot3` and compare the output with the package list
in Step 1.4. Which packages does the metapackage pull in?
