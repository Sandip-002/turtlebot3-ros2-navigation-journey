# Appendix E: What's next

> **Command tags:** `[Pi]` = SSH session on the robot's Pi, `[PC]` = normal PC terminal,
> `[Jetson]` = on the Jetson Orin Nano.

The main guide ends when the robot drives itself to a goal on a map it built (Chapter 12).
This appendix is a **status report**, not a tutorial: where I am going next, what already works,
what changed on the way, and what is still open. Things that are only plans are marked as plans.

## Where the guide stops

You now have a robot that:

- publishes lidar, odometry and TF from its onboard computer,
- talks to a PC over wifi, using ROS 2 discovery,
- builds a map (Cartographer, [Chapter 10](10-mapping-with-cartographer.md)) and saves it ([Chapter 11](11-saving-the-map.md)),
- localises and navigates on that map (Nav2, [Chapter 12](12-navigating-with-nav2.md)),
- and comes with a pre-flight checklist ([Appendix C](C-preflight-checklist.md)).

## Roadmap

| Goal | Status | Notes |
|------|--------|-------|
| **A camera on the robot** | Working with the RealSense D435i. The original Pi camera never worked | See below |
| **Replace the Pi with a Jetson Orin Nano** as the onboard computer | In progress: bringup, teleop and Cartographer run on it | See below |
| **Nav2 on the Jetson** | Planned, not yet done | |
| **Object detection on the camera images** | Planned | |
| **Semantic navigation** (going to places and objects by meaning, not only by coordinates) | Idea | Depends on the two items above |
| **Vision-language models and a robotic arm** | Idea, much later | |

## The camera

**The original camera (Raspberry Pi Camera V2.1) never worked.** The Pi did not detect it: there was
no `/dev/video0`, and forcing the `imx219` driver gave a `failed to read chip id` error, even after
re-seating both ends of the ribbon cable. I had no spare Pi or camera to swap in, so I could not tell
whether the camera, the cable or the Pi was at fault. That question is **still open**. I moved on.

**The Intel RealSense D435i did work.**

| Where | Result |
|-------|--------|
| On the PC (`realsense-viewer`) | Depth, colour and IMU all worked, over USB 2 |
| On the Pi, with ROS 2 Humble | `rs_launch.py` ran at 640×480 and 15 frames per second, with the colour image at about 14.7 Hz. A 424×240 depth profile I asked for was rejected, and the driver fell back to 640×480. The Pi also needed the `ros-humble-diagnostic-updater` package first |
| On the Pi, at first | A "requested device is not found" error, and under-voltage warnings. The cause was a **USB cable**, and swapping to the original USB 3 cable fixed it ([Appendix D](D-power-and-undervoltage.md)) |
| On the Jetson, with ROS 2 Jazzy | Worked end to end: `rqt_image_view` showed both the colour and the depth images, with colour at about 28 Hz |

On the Jetson, the camera's topics appeared under `/camera/camera/` (colour and depth images, camera
info, metadata and static transforms). I saw no IMU topics there. The only warning was
`frame's time domain is HARDWARE_CLOCK`.

## The Jetson Orin Nano

My plan is to replace the Raspberry Pi completely with a Jetson Orin Nano Developer Kit (8 GB),
which has far more computing power for camera and vision work. Where it stands:

| Item | State |
|------|-------|
| Operating system | Ubuntu 24.04 with JetPack 7.2.1, already installed on the NVMe drive when I got it |
| ROS 2 | **Jazzy** (not Humble), installed with `apt` |
| RealSense camera | Working (see above) |
| TurtleBot3 packages | Installed (`ros-jazzy-turtlebot3`, `-msgs`, `-navigation2`, `ros-jazzy-nav2-bringup`) |
| Robot bringup and teleop | Working |
| Cartographer | Runs on the Jetson, and the PC sees its topics |
| Nav2 on the Jetson | Planned |
| Onboard power | Planned (below) |

### What changed on Jazzy and the Jetson

These are differences from the Humble and Pi setup used in Chapters 04 to 12, taken from my own
notes while moving over:

| Difference | What I saw |
|------------|------------|
| **`LDS_MODEL` is required** | On Jazzy, `robot.launch.py` stopped with a `KeyError` until I set `LDS_MODEL` (I used `LDS-01`) |
| **Serial port permissions** | Bringup failed with "Error opening serial port" for the OpenCR (`/dev/ttyACM0`) and the lidar (`/dev/ttyUSB0`). The devices belong to the `dialout` group, and my user was not in it. Adding it (`sudo usermod -aG dialout $USER`, then logging in again) fixed it |
| **Teleop's message type** | On Jazzy, `ros2 topic info /cmd_vel -v` showed `teleop_keyboard` publishing a **`TwistStamped`**, where Chapter 06 uses a plain `Twist` on Humble. Check yours with that command |
| **Cartographer launch** | The Jazzy `cartographer.launch.py` has no `use_rviz` argument, so I ran RViz separately on the PC. When I started it over SSH on the Jetson, its RViz crashed because the session had no display |
| **Docker not needed** | My PC also runs Jazzy, so it could see the Jetson's topics and run RViz **without** Docker. (The Docker setup in Chapter 03 existed to match the Pi's Humble) |
| **RViz warning** | On the PC, RViz printed that the `/scan` QoS was incompatible: RViz asked for *Reliable* and the lidar offered *Best Effort* (see [Appendix A](A-concept-cheat-sheet.md#quality-of-service-qos)). The map and laser dots still appeared when I added them by topic |

### Onboard power (a plan, not a recipe)

The OpenCR board runs from about 12 V, and the Jetson's recommended supply is higher (19 V). My plan is
to power the Jetson from a larger battery through a **buck converter** (a device that steps a voltage
down), with a **voltmeter** to watch the battery. I have **not built this yet**.

> **Please do not copy this as a design.** Large lithium-polymer batteries can start fires if they are
> short-circuited, over-discharged or charged wrongly. Use a proper fuse, a rated converter, correct
> connectors, and read the datasheets for your own parts. I will describe the build once I have
> done it and checked it.

## Open issues

- **The Pi camera:** camera, cable or Pi? Never found out.
- **Early under-voltage warning** (Appendix D, Episode 1): the cause is unknown.
- **The wobbly first Nav2 run** (Chapter 13): the cause is not proven.
- **Nav2 on the Jetson:** not yet tried.
- **Jetson power:** still a plan.

## If you want to follow along

These are the chapters I expect to write next, in this order. They are a **plan**, and I may change
them:

1. The RealSense camera on ROS 2 (Pi and Jetson).
2. Moving the robot's brain to the Jetson.
3. Nav2 on the Jetson.
4. Running an object detector on the camera images.
5. Using what the camera sees to choose where to go.
