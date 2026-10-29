# Appendix A: ROS 2 concept cheat sheet

A one-stop reference for every ROS idea this guide uses. Each entry has the same four parts:

- **In plain words:** what it is.
- **In this guide:** where you used it, with the chapter link.
- **See it yourself:** a command that shows it on a running robot.
- **Easy to mix up with:** the thing people confuse it with.

> Commands marked `[container]` run inside the Docker container on the PC. Commands marked
> `[Pi]` run over SSH on the robot. Both need `source /opt/ros/humble/setup.bash` first.

**Contents:** [Building blocks](#1-building-blocks) · [Ways of talking](#2-ways-of-talking) ·
[Networking](#3-networking-under-the-hood) · [Space and time](#4-space-and-time) ·
[Robot concepts](#5-robot-concepts) · [Environment variables](#6-environment-variables) ·
[Command cheat sheet](#7-command-cheat-sheet) · [Where each idea appears](#8-where-each-idea-appears)

---

## 1. Building blocks

### ROS 2 distribution

**In plain words:** A named release of ROS 2, such as *Humble* or *Jazzy*. Each is built for one
Ubuntu version (Humble for Ubuntu 22.04, Jazzy for 24.04). Machines that talk to each other
should run the same one.
**In this guide:** The robot's Pi runs Humble, so the PC runs Humble too, in Docker.
([Chapter 00](00-before-you-start.md), [Chapter 03](03-docker-on-the-pc.md))
**See it yourself:** `printenv ROS_DISTRO`
**Easy to mix up with:** the Ubuntu version. They are linked but not the same thing.

### Package

**In plain words:** A bundle of ROS code, installed with `apt` as `ros-humble-<name>`.
The TurtleBot3 software is a set of packages.
**In this guide:** [Chapter 01](01-inspecting-a-used-robot.md) lists the installed TurtleBot3 packages.
**See it yourself:** `ros2 pkg list | grep turtlebot3`
**Easy to mix up with:** a node. A package is the *box*; nodes are the *programs* inside.

### Environment sourcing

**In plain words:** A new terminal does not know where ROS is. Running
`source /opt/ros/humble/setup.bash` makes the `ros2` command and the installed packages visible.
**In this guide:** needed in every new terminal, or put it in `~/.bashrc`
([Chapter 01](01-inspecting-a-used-robot.md), [Chapter 03](03-docker-on-the-pc.md)).
**See it yourself:** if `ros2` says *command not found*, you forgot it.
**Easy to mix up with:** installing. The software can be installed and still invisible.

### Node

**In plain words:** One small program that does one job: drive the motors, read the lidar,
display a window. A robot is many nodes working together.
**In this guide:** `/turtlebot3_node`, `/hlds_laser_publisher`, `/robot_state_publisher`,
`/cartographer_node`, `/amcl`, `/rviz2` and others
([Chapter 04](04-bringing-up-the-robot.md), [Chapter 10](10-mapping-with-cartographer.md),
[Chapter 12](12-navigating-with-nav2.md)).
**See it yourself:** `ros2 node list`, then `ros2 node info /turtlebot3_node`
**Easy to mix up with:** a computer. Many nodes run on one machine, and nodes on different
machines can still work together.

### Launch file

**In plain words:** A script that starts several nodes at once, with settings.
**In this guide:** `robot.launch.py`, `cartographer.launch.py`, `navigation2.launch.py`, `rviz2.launch.py`.
**See it yourself:** `ros2 launch turtlebot3_bringup robot.launch.py`
**Easy to mix up with:** `ros2 run`, which starts **one** node.
(`ros2 run nav2_map_server map_saver_cli` in [Chapter 11](11-saving-the-map.md).)

---

## 2. Ways of talking

ROS 2 has three ways for nodes to communicate. Choosing the right one is half of understanding ROS.

| | Topic | Service | Action |
|---|-------|---------|--------|
| **Picture** | A radio station | A phone call: one question, one answer | Ordering a delivery: confirmation, tracking updates, arrival, and you can cancel |
| **Pattern** | Continuous stream | One request, one reply | A goal, then progress updates, then a result |
| **Duration** | Runs as long as the node runs | Instant | Seconds to minutes |
| **Cancel?** | n/a | No | Yes |
| **Example here** | `/scan` | clear the costmap | `NavigateToPose` |

### Topic, publisher, subscriber

**In plain words:** A **topic** is a named channel carrying one kind of data. A **publisher**
sends messages to it, and a **subscriber** receives them. Publishers do not know who is listening.
Many publishers and many subscribers can share one topic.
**In this guide:** `/scan` (the lidar publishes, Cartographer and RViz subscribe), `/cmd_vel`
(teleop or Nav2 publishes, `turtlebot3_node` subscribes)
([Chapter 04](04-bringing-up-the-robot.md), [Chapter 06](06-driving-the-robot.md)).
**See it yourself:** `ros2 topic list -t`, `ros2 topic echo /battery_state --once`,
`ros2 topic info /cmd_vel -v` (shows publisher and subscriber names).
**Easy to mix up with:** a service. A topic streams; a service answers once.

### Message type

**In plain words:** The *shape* of the data on a topic: which fields it has and their types.
`geometry_msgs/msg/Twist` is two groups of three numbers (linear and angular speed).
**In this guide:** `LaserScan`, `Odometry`, `Twist`, `OccupancyGrid`, `BatteryState`.
**See it yourself:** `ros2 interface show geometry_msgs/msg/Twist`
**Easy to mix up with:** the topic name. Two different topics can carry the same type.

### Service

**In plain words:** A quick question and answer between two nodes. One node asks, another replies.
**In this guide:** clearing a Nav2 costmap ([Chapter 12](12-navigating-with-nav2.md)).
**See it yourself:** `ros2 service list -t`
**Easy to mix up with:** an action. If the task takes a while and you want progress, it is an action.

### Action

**In plain words:** A long-running task. You send a **goal**, get **feedback** while it runs, and
receive a **result** at the end. You can **cancel** it.
**In this guide:** clicking *Nav2 Goal* in RViz sends a `NavigateToPose` goal; inside Nav2,
the planner and the controller are also called through actions
([Chapter 12](12-navigating-with-nav2.md)).
**See it yourself:** `ros2 action list`, `ros2 action info /navigate_to_pose`
**Easy to mix up with:** a topic. A topic never tells you "I finished".

### Parameter

**In plain words:** A named setting on a node, such as a speed limit or a number of particles.
Usually loaded from a YAML file when the node starts.
**In this guide:** only read, never tuned: `ros2 param get /amcl max_particles`
([Chapter 12](12-navigating-with-nav2.md)). Also `use_sim_time`, which must stay `false` on a
real robot ([Chapter 07](07-rviz-inside-docker.md)).
**See it yourself:** `ros2 param list /amcl`
**Easy to mix up with:** an environment variable. Parameters belong to one node; environment
variables belong to a terminal.

### Lifecycle node

**In plain words:** A node with managed states: *unconfigured*, *inactive*, *active*. A manager
moves nodes through the states in order, so that, for example, the map is ready before the
localiser starts.
**In this guide:** Nav2 uses them, and its `lifecycle_manager` nodes announce when everything is
active ([Chapter 12](12-navigating-with-nav2.md)).
**See it yourself:** the end of the Nav2 launch output.
**Easy to mix up with:** an ordinary node, which just starts and runs.

---

## 3. Networking under the hood

### DDS and discovery

**In plain words:** ROS 2 is built on **DDS**, a networking layer in which every node announces
itself on the network and listens for others. There is **no central master** (ROS 1 had one).
So a node on the PC finds a node on the Pi automatically, if they are on the same network.
**In this guide:** the container sees the Pi's topics with no setup
([Chapter 05](05-two-machines-one-ros-graph.md)).
**See it yourself:** start the robot software and run `ros2 topic list` on the PC.
**Easy to mix up with:** SSH. SSH gives you a *terminal* on the Pi; DDS lets *nodes* exchange data.

### Domain ID, `ROS_LOCALHOST_ONLY` and the middleware

**In plain words:** Nodes only see each other if they use the same **domain ID** (default `0`).
`ROS_LOCALHOST_ONLY=1` confines a node to its own machine, so it must be `0` for a robot on the
network. The **RMW** is the DDS implementation; Humble uses Fast DDS by default, and both
machines should use the same one.
**In this guide:** both machines used the defaults ([Chapter 05](05-two-machines-one-ros-graph.md)).
**See it yourself:** `printenv | grep -E "ROS|RMW"`

### Quality of Service (QoS)

**In plain words:** Settings that say how a topic treats lost or late messages. Two matter most:
*Reliability* (**Reliable** retries lost messages, **Best Effort** does not) and
*Durability* (**Volatile** gives only new messages, **Transient Local** also gives the last
message to late joiners).
A publisher *offers* and a subscriber *requests*. They connect only if the offer is at least as
good as the request: a Reliable subscriber needs a Reliable publisher, and a Transient Local
subscriber needs a Transient Local publisher.
**In this guide:** `/scan` is Best Effort, and `/map` is Transient Local
([Chapter 04](04-bringing-up-the-robot.md), [Chapter 10](10-mapping-with-cartographer.md),
[Chapter 11](11-saving-the-map.md)).
**See it yourself:** `ros2 topic info /map -v`
**Easy to mix up with:** a broken network. A QoS mismatch can look like "the topic has data but my
display shows nothing".

---

## 4. Space and time

### Frame and transform (TF)

**In plain words:** A **frame** is a coordinate system attached to something (the map, the robot's
body, the lidar). A **transform** says where one frame is relative to another. Chained together
they form the **TF tree**, which lets ROS convert a lidar reading into map coordinates.
**In this guide:** `map → odom → base_footprint → base_link → base_scan (the lidar)` and the wheels,
IMU and camera below `base_link` ([Chapter 08](08-no-transform-and-the-clock.md)).
**See it yourself:** `ros2 run tf2_ros tf2_monitor`
**Easy to mix up with:** a topic's *message*. TF travels on the topics `/tf` and `/tf_static`.

### `/tf` and `/tf_static`

**In plain words:** `/tf` carries transforms that change (the robot moving, wheels turning).
`/tf_static` carries fixed ones, published once (the lidar is bolted to the robot).
**In this guide:** the "delay" of static frames just grows with the age of the robot software, and
is harmless ([Chapter 09](09-time-sync-without-internet.md)).
**See it yourself:** `ros2 topic list | grep tf`

### Timestamp and clock

**In plain words:** Every transform and most messages carry a timestamp from the **sending
machine's own clock**. ROS does not synchronise clocks between machines. If two machines disagree
about the time, tools that compare their stamps fail, even though the data arrives.
**In this guide:** the Pi's clock was about 195 days behind
([Chapter 08](08-no-transform-and-the-clock.md)). The fix was a time server on the PC
([Chapter 09](09-time-sync-without-internet.md)).
**See it yourself:** `date` on both machines, and `tf2_monitor` delays.
**Easy to mix up with:** a network problem. Check the clocks before you blame the wifi.

### Units and directions

**In plain words:** ROS uses SI units: metres, seconds, radians. A robot's **x** points forward,
**y** to the left, **z** up. A positive rotation turns **counter-clockwise**, seen from above, which
means turning **left**.
**In this guide:** `Twist` uses metres per second and radians per second
([Chapter 06](06-driving-the-robot.md)).

---

## 5. Robot concepts

### Odometry

**In plain words:** The robot's estimate of its own movement, calculated from how far the wheels
have turned. It is smooth but **drifts** over time, because small errors add up.
**In this guide:** `/odom` and the `odom` frame ([Chapter 04](04-bringing-up-the-robot.md)).
**See it yourself:** `ros2 topic echo /odom --once`

### Laser scan

**In plain words:** One lidar sweep: a list of distances to obstacles at many angles around the robot.
**In this guide:** `/scan`, from the LDS-01 ([Chapter 04](04-bringing-up-the-robot.md)).
**See it yourself:** `ros2 topic hz /scan`

### Occupancy grid and map files

**In plain words:** A map as a grid of cells, each *free*, *occupied* or *unknown*. Saved as an
image (`.pgm`: black occupied, white free, grey unknown) plus a description file (`.yaml`) with the
`resolution` (metres per pixel) and the `origin` (where the image sits in the `map` frame).
**In this guide:** `/map` ([Chapter 10](10-mapping-with-cartographer.md)) and the saved files
([Chapter 11](11-saving-the-map.md)).
**See it yourself:** `cat /root/maps/<your_map>.yaml`

### SLAM

**In plain words:** *Simultaneous Localisation And Mapping*: building a map while working out where
the robot is in it, by matching each lidar scan against the map so far. Driving a loop lets it
correct accumulated drift.
**In this guide:** Cartographer ([Chapter 10](10-mapping-with-cartographer.md)).

### Localisation (AMCL)

**In plain words:** Finding the robot's position on a **known** map. AMCL keeps thousands of
guesses (*particles*) and keeps the ones that match the lidar scan. A tight clump means it is
confident, and the **covariance** is the same confidence as numbers (take square roots of the
variances to get metres or radians).
**In this guide:** *2D Pose Estimate*, the green arrows, `/amcl_pose`
([Chapter 12](12-navigating-with-nav2.md)).
**Easy to mix up with:** SLAM. SLAM builds the map; localisation uses one that already exists.

### Costmap and inflation

**In plain words:** A grid of "how bad is it to drive here". The **global costmap** covers the
whole map and is used for planning routes. The **local costmap** is a small window around the
robot built from the live lidar, and is used for steering around things. **Inflation** raises the
cost near obstacles so the robot keeps its distance.
**In this guide:** the coloured halos in RViz ([Chapter 12](12-navigating-with-nav2.md)).

### The Nav2 pipeline

**In plain words:** Nav2 receives a goal as an **action**. The *planner* finds a route on the global
costmap, the *controller* follows it using the local costmap and publishes `/cmd_vel`, and
*recovery behaviours* get the robot unstuck. `map_server` provides the map and `amcl` provides the
robot's position.
**In this guide:** [Chapter 12](12-navigating-with-nav2.md), and what to check when it misbehaves in
[Chapter 13](13-wobbly-navigation-and-the-preflight-checklist.md).

### Mapping, localising, navigating: three stages

| Stage | Question it answers | Program | Chapter |
|-------|--------------------|---------|---------|
| Mapping | What does this place look like? | Cartographer | [10](10-mapping-with-cartographer.md), [11](11-saving-the-map.md) |
| Localising | Where am I on this map? | AMCL | [12](12-navigating-with-nav2.md) |
| Navigating | How do I get there? | Nav2 planner and controller | [12](12-navigating-with-nav2.md) |

---

## 6. Environment variables

| Variable | Meaning | Value in this guide |
|----------|---------|---------------------|
| `ROS_DISTRO` | Which ROS 2 release is loaded | `humble` |
| `TURTLEBOT3_MODEL` | Which TurtleBot3 variant | `waffle_pi` |
| `LDS_MODEL` | Which lidar | `LDS-01` |
| `ROS_DOMAIN_ID` | Which ROS "network" you join | not set (default `0`) |
| `ROS_LOCALHOST_ONLY` | Whether nodes stay on this machine | `0` |
| `RMW_IMPLEMENTATION` | Which DDS implementation | not set (default) |
| `DISPLAY` | Where GUI windows are drawn | `:0` |

---

## 7. Command cheat sheet

| I want to... | Command | Chapter |
|--------------|---------|---------|
| Load ROS in this terminal | `source /opt/ros/humble/setup.bash` | [01](01-inspecting-a-used-robot.md) |
| List installed TurtleBot3 packages | `ros2 pkg list \| grep turtlebot3` | [01](01-inspecting-a-used-robot.md) |
| Start a set of nodes | `ros2 launch <package> <file>.launch.py` | [04](04-bringing-up-the-robot.md) |
| Start one node | `ros2 run <package> <executable>` | [06](06-driving-the-robot.md), [11](11-saving-the-map.md) |
| List nodes | `ros2 node list` | [04](04-bringing-up-the-robot.md) |
| List topics with types | `ros2 topic list -t` | [04](04-bringing-up-the-robot.md) |
| See messages on a topic | `ros2 topic echo <topic>` (`--once` for one) | [04](04-bringing-up-the-robot.md) |
| Measure a topic's rate | `ros2 topic hz <topic>` | [04](04-bringing-up-the-robot.md), [08](08-no-transform-and-the-clock.md) |
| See publishers, subscribers and QoS | `ros2 topic info <topic> -v` | [06](06-driving-the-robot.md), [10](10-mapping-with-cartographer.md) |
| Show a message's fields | `ros2 interface show <type>` | [04](04-bringing-up-the-robot.md) |
| Check transform delays | `ros2 run tf2_ros tf2_monitor` | [08](08-no-transform-and-the-clock.md), [09](09-time-sync-without-internet.md) |
| List services | `ros2 service list -t` | [12](12-navigating-with-nav2.md) |
| List actions | `ros2 action list` | [12](12-navigating-with-nav2.md) |
| Read a node's parameter | `ros2 param get <node> <name>` | [12](12-navigating-with-nav2.md) |
| Save the map | `ros2 run nav2_map_server map_saver_cli -f <path>` | [11](11-saving-the-map.md) |
| Refresh a cached node list | `ros2 daemon stop` | [05](05-two-machines-one-ros-graph.md) |

---

## 8. Where each idea appears

| Idea | Chapters |
|------|----------|
| Distribution, package, sourcing | [00](00-before-you-start.md), [01](01-inspecting-a-used-robot.md), [03](03-docker-on-the-pc.md) |
| Node, launch file | [04](04-bringing-up-the-robot.md), [10](10-mapping-with-cartographer.md), [12](12-navigating-with-nav2.md) |
| Topic, publisher, subscriber, message | [04](04-bringing-up-the-robot.md), [06](06-driving-the-robot.md), [07](07-rviz-inside-docker.md) |
| DDS discovery, domain ID | [05](05-two-machines-one-ros-graph.md) |
| QoS | [04](04-bringing-up-the-robot.md), [06](06-driving-the-robot.md), [10](10-mapping-with-cartographer.md) |
| TF, timestamps, clocks | [08](08-no-transform-and-the-clock.md), [09](09-time-sync-without-internet.md), [13](13-wobbly-navigation-and-the-preflight-checklist.md) |
| SLAM, occupancy grid | [10](10-mapping-with-cartographer.md), [11](11-saving-the-map.md) |
| Services, actions, lifecycle, parameters | [12](12-navigating-with-nav2.md) |
| Localisation, costmaps | [12](12-navigating-with-nav2.md) |
