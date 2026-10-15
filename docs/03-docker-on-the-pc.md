# Chapter 03: Why Docker, and setting it up on the PC

> **Command tags:** `[Pi]` = SSH session on the robot, `[PC]` = normal PC terminal,
> `[PC-container]` = inside the Docker container on the PC.

## Goal

Run **ROS 2 Humble** on a PC whose own Ubuntu pairs with a different ROS release, with the
TurtleBot3 packages installed, so the PC and the Pi use the same distribution.

## ROS concepts in this chapter

Docker is not part of ROS, but it gives you a clean ROS install to work in.

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **ROS 2 distribution** | The container holds Humble, matching the Pi, even though the PC's own Ubuntu pairs with Jazzy | `printenv ROS_DISTRO` inside the container |
| **Packages** | The TurtleBot3 packages are installed with `apt` inside the container, exactly as on the Pi | `ros2 pkg list \| grep turtlebot3` |
| **Environment sourcing** | A new shell does not load ROS by itself. You have to run `source /opt/ros/humble/setup.bash` (or put it in `~/.bashrc`) | `ros2` says *command not found* before sourcing |
| **Network and discovery** *(preview)* | `--network host` lets the container use the PC's network directly. This is what lets ROS 2 find the Pi in Chapter 05 | |

Docker words you need:

| Word | Meaning |
|------|---------|
| **Image** | A frozen template, like an installer. `osrf/ros:humble-desktop` is an image with ROS 2 Humble in it |
| **Container** | A running (or stopped) copy made from an image. Changes you make inside it stay inside it |

## Before you start

- [ ] Chapter 02 is done (not strictly needed for this chapter, but you will need the Pi next)
- [ ] The PC has internet access and about **6 GB** of free disk space
- [ ] You have `sudo` rights on the PC

## Steps

### Step 3.1: Understand why Docker

My PC runs Ubuntu 24.04, which pairs with ROS 2 **Jazzy**. The robot's Pi runs Ubuntu 22.04 with
ROS 2 **Humble**, and different distributions on different machines are not officially supported.
I had three options:

| Option | Cost |
|--------|------|
| Reflash the Pi to Ubuntu 24.04 and Jazzy | I would lose the working robot setup and have to reinstall and check everything |
| Dual-boot the PC with Ubuntu 22.04 | Changes the whole PC for one project |
| **Run Humble in Docker on the PC** | Nothing on the PC or the Pi changes. The container can be deleted and rebuilt |

I chose Docker. The Pi stays as it is, and the PC gets a Humble environment in a box.

### Step 3.2: Install Docker

I used Docker's convenience script. It is quick, and it is meant for development machines,
not production servers.

```bash
# [PC]
curl -fsSL https://get.docker.com -o get-docker.sh
less get-docker.sh          # read what you are about to run as root, then press q
sudo sh get-docker.sh
```

To run `docker` without typing `sudo` every time, add yourself to the `docker` group, then
**log out and back in** (or reboot) so it takes effect:

```bash
# [PC]
sudo usermod -aG docker $USER
```

### Step 3.3: Check that Docker works

```bash
# [PC]
docker --version
docker run hello-world
```

**You should see** a version number (mine was Docker 29.8.2), then a message starting with
`Hello from Docker!`. That one command downloaded a tiny image, started a container, ran it, and
stopped it.

### Step 3.4: Download the ROS 2 Humble image

```bash
# [PC]
docker pull osrf/ros:humble-desktop
docker images
```

It is a large download (about 1 GB compressed; about 5 GB on disk once unpacked).

### Step 3.5: Start a throwaway container and look around

```bash
# [PC]
docker run -it --rm --network host osrf/ros:humble-desktop bash
```

What the options mean:

| Option | Meaning |
|--------|---------|
| `-it` | Give me an interactive terminal inside the container |
| `--rm` | Delete the container when I exit (**including anything I installed in it**) |
| `--network host` | Use the PC's network directly, so ROS 2 can find the robot (Chapter 05) |

Inside the container:

```bash
# [PC-container]
printenv ROS_DISTRO
ros2 topic list
exit
```

**You should see:** `humble`, then just `/parameter_events` and `/rosout` (there is no robot
connected to this container yet).

### Step 3.6: Make a container that keeps its changes

The base image has ROS 2 Humble but **not** the TurtleBot3 packages, and with `--rm` anything
you install disappears on exit. So create a named container *without* `--rm`:

```bash
# [PC]
docker run -it --network host --name tb3_pc osrf/ros:humble-desktop bash
```

Inside it, install the TurtleBot3 packages. You are `root` in the container, so no `sudo`:

```bash
# [PC-container]
apt update
apt install -y ros-humble-turtlebot3 ros-humble-turtlebot3-msgs \
  ros-humble-turtlebot3-cartographer ros-humble-turtlebot3-navigation2
```

Then make the shell set up ROS by itself every time you open it:

```bash
# [PC-container]
echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc
echo 'export TURTLEBOT3_MODEL=waffle_pi' >> ~/.bashrc
source ~/.bashrc
ros2 pkg list | grep turtlebot3
exit
```

Use `burger` instead of `waffle_pi` if that is your robot.

### Step 3.7: Save your work as an image

```bash
# [PC]
docker commit tb3_pc tb3_pc_image
docker images
```

This freezes the container, with the TurtleBot3 packages installed, as a new image named
`tb3_pc_image`. In Chapter 07 you will start a new container from it with GUI support.

### Step 3.8 (recommended): Make it reproducible with a Dockerfile

`docker commit` works, but nobody can see what went into the image. A **Dockerfile** is a short
text recipe that anyone can rebuild. This is the same setup as Steps 3.6 and 3.7:

```dockerfile
FROM osrf/ros:humble-desktop

RUN apt-get update && apt-get install -y \
    ros-humble-turtlebot3 \
    ros-humble-turtlebot3-msgs \
    ros-humble-turtlebot3-cartographer \
    ros-humble-turtlebot3-navigation2 \
 && rm -rf /var/lib/apt/lists/*

ENV TURTLEBOT3_MODEL=waffle_pi
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc
```

```bash
# [PC]  (in the folder containing the Dockerfile)
docker build -t tb3_pc_image:dockerfile .
```

> **Untested:** I wrote this Dockerfile after the fact from the manual steps. I built my own
> image with Steps 3.6 and 3.7. If you try the Dockerfile, check it with
> `ros2 pkg list | grep turtlebot3` inside a container made from it.

### Container cheat sheet

| I want to... | Command |
|--------------|---------|
| See all containers, running or stopped | `docker ps -a` |
| Start a stopped container | `docker start <name>` |
| Open another terminal in a running container | `docker exec -it <name> bash` |
| Stop a container | `docker stop <name>` |
| See my images | `docker images` |
| Delete a container (**its changes are lost**) | `docker rm <name>` |

A container's changes survive a stop. They are lost only if you delete it with `docker rm`, or
if it was started with `--rm`.

`docker ps -a` may show a status such as `Exited (137)`. Code 137 means the container was
killed rather than stopped cleanly. This usually happens when the PC shuts down or Docker has
to force-stop it. Nothing is lost: run `docker start <name>` again.

## Checklist

- [ ] `docker run hello-world` works without `sudo`
- [ ] `osrf/ros:humble-desktop` appears in `docker images`
- [ ] A throwaway container prints `humble` for `printenv ROS_DISTRO`
- [ ] The container `tb3_pc` has the TurtleBot3 packages (`ros2 pkg list | grep turtlebot3`)
- [ ] You committed it as the image `tb3_pc_image`
- [ ] You can explain the difference between an image and a container

## When it broke

| | |
|---|---|
| **Symptom** | I wanted to test keyboard teleop from the PC, but the `turtlebot3_teleop` package was not there. `ros2 run` reports `Package 'turtlebot3_teleop' not found` when a package is missing |
| **What I thought it was** | Something wrong with my ROS setup in the container |
| **What it really was** | The `osrf/ros:humble-desktop` image contains ROS 2, but not the TurtleBot3 packages |
| **Fix** | Install `ros-humble-turtlebot3` and the related packages in a container that keeps its changes (Step 3.6). For that first test I drove the robot from the Pi over SSH instead |
| **Lesson** | A new image is a blank ROS install. Anything extra has to be installed, and with `--rm` it is thrown away when you exit |

## Recap

- You chose Docker to get ROS 2 Humble on a Jazzy-era PC without touching the robot.
- You met the image and the container, and the idea that a ROS distribution is something you can match on both machines.
- You built `tb3_pc_image`, a Humble image with the TurtleBot3 packages.
- Next: start the robot's software on the Pi and look at its nodes and topics.

## Try it yourself (optional)

Start a throwaway container with `--rm`, install any small package with `apt`, exit, start another
one, and check whether the package is still there. Then repeat with a named container without
`--rm`.
