# TurtleBot3 Waffle Pi + ROS 2 Humble: From "Used Robot" to Autonomous Navigation

A beginner-friendly, **real** log of getting a second-hand TurtleBot3 Waffle Pi
(Raspberry Pi 3) to build a map of a lab and drive itself to goals with Nav2.

This is not a polished tutorial that pretends everything worked the first time.
Every step is here, **including the wrong turns**: the wifi that wouldn't connect,
the transform errors that turned out to be a clock problem, and the hypothesis that
was wrong before we found the real cause. If you are stuck on something similar,
the debugging stories are probably the most useful part.

> **Status:** work in progress. Chapters are written one at a time.
> Chapters marked `TODO` are planned but not written yet.

---

## What you will end up with

- A robot that publishes lidar, odometry and TF data from the Pi.
- A PC (Ubuntu 24.04 + Docker) running **ROS 2 Humble in a container** and talking to that robot over wifi.
- A saved map of a room, built with Cartographer (SLAM).
- Nav2 localising on that map and driving to goals you click in RViz.
- A pre-flight checklist so the same problems do not bite you twice.

## Hardware and software used

| Part | Details |
|------|---------|
| Robot | TurtleBot3 Waffle Pi (second-hand), OpenCR board, LDS-01 lidar, Raspberry Pi 3 |
| Robot OS | Ubuntu 22.04.5 LTS (aarch64), ROS 2 Humble (already installed when I got it) |
| Robot packages | TurtleBot3 packages 2.3.6 (`turtlebot3_msgs` 2.4.0) |
| PC | Ubuntu 24.04.4 LTS with ROS 2 Jazzy installed on the host (not used for this project) |
| PC ROS setup | Docker 29.8.2, container from `osrf/ros:humble-desktop`, host networking, X11 for RViz |
| Network | One wifi router, no internet access on it |

## How the pieces fit together

```
   ┌────────────── Robot ──────────────┐            ┌──────────── PC ────────────┐
   │ Raspberry Pi 3 (Ubuntu 22.04)     │            │ Ubuntu 24.04 host          │
   │  ROS 2 Humble                     │   wifi     │  ┌─ Docker (Humble) ─────┐ │
   │  turtlebot3_bringup:              │ ◄────────► │  │ Cartographer / Nav2   │ │
   │   - robot driver  (OpenCR, motors)│  DDS over  │  │ RViz2 (GUI via X11)   │ │
   │   - lidar driver                  │  the LAN   │  │ teleop                │ │
   │   - robot_state_publisher         │            │  └───────────────────────┘ │
   └───────────────────────────────────┘            └────────────────────────────┘
```

The Pi does the hardware work. The PC does the heavy thinking (mapping, planning).
They find each other automatically because ROS 2 uses DDS discovery (Chapter 05).

## How to read this guide

Every chapter has the same parts, in the same order:

1. **Goal**: what you will have at the end.
2. **ROS concepts in this chapter**: which idea (topic, publisher, service, action...) you are actually using, and how to *see* it in a terminal.
3. **Steps**: commands, each tagged with where it runs (see below), plus what you should see.
4. **Checklist**: a short summary you can tick off.
5. **When it broke**: the debugging story (symptom, what I guessed, what I tested, what it really was).
6. **Recap**.

### Where does this command run?

Beginners (including me) lose a lot of time running the right command on the wrong machine,
so every code block is tagged:

| Tag | Meaning |
|-----|---------|
| `[Pi]` | In an SSH session on the robot's Raspberry Pi |
| `[PC]` | In a normal terminal on the PC (outside Docker) |
| `[PC-container]` | Inside the Docker container on the PC |

Placeholders like `<PI_IP>` are used instead of real addresses and credentials.
**Never commit passwords or wifi keys.**

---

## Chapters

| # | Chapter | You will | Debug story | Status |
|---|---------|----------|-------------|--------|
| 00 | [Before you start](docs/00-before-you-start.md) | Check the hardware, safety, conventions | | Draft |
| 01 | [Inspecting a used robot](docs/01-inspecting-a-used-robot.md) | Find out what is already installed before installing anything | Could not log in with the default credentials | Draft |
| 02 | [Getting the Pi online](docs/02-getting-the-pi-online.md) | Put the Pi on wifi and log in over SSH | Pi could not join the lab wifi; its IP address changed | Draft |
| 03 | [Why Docker, and setting it up](docs/03-docker-on-the-pc.md) | Run ROS 2 Humble on a PC that has Jazzy | The base image had no TurtleBot3 packages | Draft |
| 04 | [Bringing up the robot](docs/04-bringing-up-the-robot.md) | Launch the robot and look at nodes and topics | No visible failure, but a wrong clock went unnoticed until Chapter 08 | Draft |
| 05 | [Two machines, one ROS graph](docs/05-two-machines-one-ros-graph.md) | See the Pi's topics from inside the container | None: it worked with the defaults | Draft |
| 06 | [Driving the robot](docs/06-driving-the-robot.md) | Teleop and `/cmd_vel` | An error-looking message that turned out harmless | Draft |
| 07 | [RViz inside Docker](docs/07-rviz-inside-docker.md) | Show GUI windows from a container | Typos in long commands; the display permission had to be granted again | Draft |
| 08 | [Debug case: "No transform"](docs/08-no-transform-and-the-clock.md) | Find out why the TF tree looked broken | Wrong hypothesis (packet loss); the real cause was the clock | Draft |
| 09 | [Time sync without internet](docs/09-time-sync-without-internet.md) | PC as time server, Pi as client | A clock-setting command that added its own delay | Draft |
| 10 | [Mapping with Cartographer](docs/10-mapping-with-cartographer.md) | Drive around and build a map (SLAM) | | Draft |
| 11 | [Saving the map](docs/11-saving-the-map.md) | Write the map to disk and back it up | | Draft |
| 12 | [Navigating with Nav2](docs/12-navigating-with-nav2.md) | Localise, set an initial pose, send goals | | Draft |
| 13 | [Fixing wobbly Navigation](docs/13-wobbly-navigation-and-the-preflight-checklist.md) | Confirm pre-flight checklist, before running | | Draft |
| A | [Concept cheat sheet](docs/A-concept-cheat-sheet.md) | One section per ROS idea, with chapter links | | Draft |
| B | [Troubleshooting index](docs/B-troubleshooting-index.md) | "My symptom is..." and where to look | | Draft |
| C | Pre-flight checklist | One page to print | | TODO |
| D | [Power and undervoltage](docs/D-power-and-undervoltage.md) | The warning, and the cable that fixed one cause of it | One cause solved, one never explained | Draft |
| E | [What's next](docs/E-whats-next.md) | Camera, Jetson, semantic navigation | | Draft |

---

## ROS concept map

Where each core ROS 2 idea shows up in the journey:

| Concept | Where you meet it | Chapter |
|---------|-------------------|---------|
| **Node** | Robot driver, lidar driver, `robot_state_publisher`, `rviz2`, Cartographer | 04 |
| **Launch file** | `robot.launch.py`, `cartographer.launch.py`, `navigation2.launch.py` | 04, 10, 12 |
| **Topic, publisher, subscriber** | `/scan`, `/odom` (robot publishes), `/cmd_vel` (teleop publishes, robot subscribes) | 04, 06 |
| **Message types** | `LaserScan`, `Odometry`, `Twist`, `OccupancyGrid` | 04, 06, 10 |
| **Discovery / DDS** | Container sees the Pi's topics with no extra setup | 05 |
| **TF (transforms) and time** | `/tf`, `/tf_static`, the `map → odom → base_footprint` chain, why clocks matter | 08, 09 |
| **Services** | Nav2 node management and costmap clearing (listed and called by hand) | 12 |
| **Actions** | The "Nav2 Goal" click sends a `NavigateToPose` goal; it reports feedback and a result | 12 |
| **Lifecycle nodes** | How Nav2 brings its nodes up in order | 12 |
| **Parameters** | `use_sim_time` and the Nav2 YAML file (read-only tour) | 12 |
| **QoS (sidebar)** | Why the map is "latched" and why RViz display settings must match | 10, 12 |

> `TODO: before publishing, capture real output of ros2 node list / topic list / service list / action list`
> `on the running robot so every row above is backed by something the reader can reproduce.`

---

## Repo layout (planned)

```
.
├── README.md
├── docs/            # one file per chapter + appendices
├── docker/          # Dockerfile + run script that reproduce the PC container
├── scripts/         # pre-flight check, helper scripts
├── assets/          # screenshots (cropped, no personal info)
└── maps/            # (optional) example map
```

## License

`TODO: choose one. A common choice is CC BY 4.0 for the text and MIT for the scripts.`
