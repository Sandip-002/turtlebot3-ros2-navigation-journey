# Chapter 10: Mapping with Cartographer

> **Command tags:** `[Pi]` = SSH session on the robot, `[PC]` = normal PC terminal,
> `[PC-container]` = inside the Docker container on the PC.

## Goal

Drive the robot around a room while **Cartographer** builds a map from the lidar, and see which
nodes and topics make that happen.

## ROS concepts in this chapter

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **SLAM** | *Simultaneous Localisation And Mapping*: working out where the robot is **while** building the map it is working out where it is in | the map growing in RViz |
| **Subscriber** | `cartographer_node` subscribes to `/scan` to receive lidar data | `ros2 topic info /scan -v` |
| **Publisher** | `cartographer_occupancy_grid_node` publishes the finished map on `/map` | `ros2 topic info /map -v` |
| **Message type: `OccupancyGrid`** | A map as a grid of cells, each one "free", "occupied" or "unknown" | `ros2 interface show nav_msgs/msg/OccupancyGrid` |
| **TF** | Cartographer provides the `map → odom` transform, which is why the `map` frame only appears once it is running | the TF display in RViz |
| **QoS, in detail** | `/map` is published as *Transient Local* (a "latched" topic), and `/scan` as *Best Effort* | the box in Step 10.4 |
| **Launch file** | `cartographer.launch.py` starts Cartographer and RViz together | Step 10.2 |

**What SLAM does, in plain words.** Each lidar scan is a snapshot of the walls around the robot.
Cartographer lines up each new snapshot with the map it has built so far. The way it needs to
shift the snapshot tells it how the robot moved. As the robot explores, the map grows. When the
robot comes back to a place it has seen before (a *loop*), Cartographer can correct small errors
that have built up along the way. That is why driving a loop makes better maps.

## Before you start

- [ ] Chapters 04 to 09 are done: bringup works, and the Pi and the PC agree on the time
- [ ] The Pi's clock is synced (`timedatectl timesync-status`), and `tf2_monitor` shows small delays for the moving frames
- [ ] The GUI container works (Chapter 07), with `xhost +local:docker` run in this session
- [ ] The battery is well charged
- [ ] You have a room with walls, furniture and open floor to drive in

## Steps

### Step 10.1: Start the robot software

```bash
# [Pi]
source /opt/ros/humble/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
export LDS_MODEL=LDS-01
ros2 launch turtlebot3_bringup robot.launch.py
```

Leave it running.

### Step 10.2: Start Cartographer

```bash
# [PC]
xhost +local:docker
docker start tb3_pc_gui
docker exec -it tb3_pc_gui bash
```

```bash
# [PC-container]
source /opt/ros/humble/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
ros2 launch turtlebot3_cartographer cartographer.launch.py
```

**You should see** RViz open (its title bar shows `tb3_cartographer.rviz`) with the robot and the
beginnings of a map.

The map starts out small, built from the first few scans, and fills in as you drive.

<img src="../assets/10-cartographer-mapping.jpeg" width="1000" alt="Photo of RViz while Cartographer was mapping the lab: white free space, black walls">


*A photo of my monitor, taken during an early mapping run in the lab. White is free space, black
is walls and obstacles, and the teal area is unknown. This map is rough because I had only driven
the robot for a short time.*

### Step 10.3: See which nodes are running

Open a second terminal in the container and look:

```bash
# [PC]
docker exec -it tb3_pc_gui bash
```

```bash
# [PC-container]
source /opt/ros/humble/setup.bash
ros2 node list
```

**What I saw:**

```text
/cartographer_node
/cartographer_occupancy_grid_node
/rviz2
/transform_listener_impl_59c11064c6f0
/transform_listener_impl_5f2fde317870
```

| Node | Its job |
|------|---------|
| `/cartographer_node` | The SLAM part: receives scans, works out the robot's position, and builds the map internally |
| `/cartographer_occupancy_grid_node` | Turns Cartographer's internal map into the `OccupancyGrid` message on `/map` |
| `/rviz2` | The display window |
| `/transform_listener_impl_...` | Hidden helper nodes that programs create when they listen to TF. Cartographer and RViz each have one. You can ignore them |

The robot's own nodes from Chapter 04 (`/turtlebot3_node` and the others) are still running on the
Pi. My first `ros2 node list` showed only the PC-side nodes, even though the lidar on the Pi was
already publishing `/scan` (Step 10.4). I believe the robot's nodes had not been discovered yet when
I ran it. If yours is missing them, wait a few seconds and run the command again.

### Step 10.4: See how the map and the lidar data travel

```bash
# [PC-container]
ros2 topic info /map -v
ros2 topic info /scan -v
```

**What I saw, shortened:**

`/map`:

| Role | Node | Reliability | Durability |
|------|------|-------------|------------|
| Publisher | `cartographer_occupancy_grid_node` | RELIABLE | **TRANSIENT_LOCAL** |
| Subscriber | `rviz2` | RELIABLE | VOLATILE |

`/scan`:

| Role | Node | Reliability | Durability |
|------|------|-------------|------------|
| Publisher | `hlds_laser_publisher` (on the Pi) | **BEST_EFFORT** | VOLATILE |
| Subscriber | `cartographer_node` | **BEST_EFFORT** | VOLATILE |
| Subscriber | `rviz2` | RELIABLE | VOLATILE |

> **QoS rules in one paragraph.** A publisher *offers* a quality of service and a subscriber
> *requests* one. They connect only if the offer is at least as good as the request.
> A **Reliable** subscriber needs a **Reliable** publisher, while a **Best Effort** subscriber
> accepts either. A **Transient Local** subscriber needs a **Transient Local** publisher
> (it then receives the last message sent before it joined), while a **Volatile** subscriber
> accepts either.
>
> - **Lidar to Cartographer:** *Best Effort* meets *Best Effort*. That is fine. Dropping an old
>   scan is better than waiting for it, because a newer one arrives in a fraction of a second.
> - **`/map` to RViz:** the map is *Transient Local*, and RViz asks for *Volatile*. That is
>   compatible. *Transient Local* on the publisher means a program that joins late can still
>   receive the last map, if it asks for the same.
<!-- > - **Lidar to RViz:** RViz asks for *Reliable* but the lidar offers *Best Effort*. By the rule
>   above, those two would **not** connect.
>
> `TODO (open question): in my RViz the scan points are visible, which seems to contradict the
> last point. Open RViz, expand LaserScan, then Topic, and note the Reliability Policy shown.
> Write here what yours says and whether the dots appear. If a LaserScan display ever shows
> nothing while the scan topic has data, set its Reliability Policy to "Best Effort".` -->

<!-- I will check this TODO later because I now have moved to the Jetson Orin Nano-->

### Step 10.5: Drive and build the map

In a third container terminal, start teleop (Chapter 06):

```bash
# [PC-container]
source /opt/ros/humble/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
ros2 run turtlebot3_teleop teleop_keyboard
```

Drive **slowly** and watch the map in RViz. Remember that `w`, `x`, `a` and `d` change the speed in
steps, and `s` stops the robot.

Tips for a good map:

- **Go slowly**, and turn slowly. Fast turns blur the scan matching.
- **Let the lidar see the walls.** Cartographer needs features to match, and a large empty space
  or a long plain corridor gives it very little.
- **Drive a loop and come back to your starting point.** Revisiting a place lets Cartographer
  correct drift.
- **Cover everything you want to navigate in later.** Anything you did not drive past is
  unknown space in the map.
- **Keep an eye on the battery.** A weak battery can make driving jerky (Chapter 13).
- Glass, mirrors and very dark or shiny surfaces can confuse a lidar.

### Step 10.6: Read the map

| Colour in RViz | Meaning |
|----------------|---------|
| White | Free space the lidar has seen through |
| Black | Occupied: walls and obstacles |
| Teal or grey | Unknown: nothing has been seen there yet |

The thin dots that follow the walls are the current lidar readings. If they match the black
lines, the robot knows where it is. If the same wall appears twice, slightly shifted, the map has
drifted: stop, go back, and try again slower.

When you are happy with the map, **do not stop Cartographer yet.** Chapter 11 saves it.

## Checklist

- [ ] Cartographer starts and RViz shows a map that grows as you drive
- [ ] `ros2 node list` shows `/cartographer_node` and `/cartographer_occupancy_grid_node`
- [ ] `ros2 topic info /map -v` shows `cartographer_occupancy_grid_node` publishing
- [ ] You drove at low speed, including a loop back to the start
- [ ] Walls appear once, as clean lines, not doubled
- [ ] You can explain what SLAM does, and why a loop helps

## When it broke

Nothing new broke in this chapter. The transform warnings that RViz showed when I first ran
Cartographer were the clock problem from [Chapter 08](08-no-transform-and-the-clock.md), and
they went away once the clocks agreed (Chapter 09).

If your map looks wrong, here is what I would check (general guidance, not a record of my
own failures):

| Symptom | Likely cause | What to check |
|---------|--------------|---------------|
| RViz shows "No transform" warnings | Clocks differ between the Pi and the PC | `tf2_monitor`, and Chapter 09 |
| The map does not grow at all | No scan data reaches Cartographer | `ros2 topic hz /scan` in the container |
| Walls appear twice or the map smears | Driving or turning too fast, or wheels slipping | Go slower, and make sure the floor gives the wheels grip |
| The map breaks up in a long, plain corridor | Too few features for scan matching | Drive past furniture or doorways, or accept a rougher map there |
| The robot jerks or the map jumps | Weak battery, or power problems on the Pi | Check the voltage (Chapter 13) |

## Recap

- You ran **Cartographer** and saw the map grow as you drove.
- You met **SLAM**, the **OccupancyGrid** message, and the **QoS** rules that decide whether a publisher and a subscriber can connect.
- You saw one publisher (`/map`) and two subscribers to the lidar, the pub/sub idea at work on a real task.
- Next: save the map to a file, so it survives after Cartographer stops.

## Try it yourself (optional)

Run `ros2 topic hz /map` while you drive, then stand still for a minute. How often does the map
update? Then run `ros2 topic echo /map --once` and look at `info.resolution` and `info.width`.
What size, in metres, is one cell, and how many metres wide is your map?
