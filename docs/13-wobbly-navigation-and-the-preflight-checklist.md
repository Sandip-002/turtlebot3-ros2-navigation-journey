# Chapter 13: Debug case, wobbly navigation, and the pre-flight checklist

> **Command tags:** `[Pi]` = SSH session on the robot, `[PC]` = normal PC terminal,
> `[PC-container]` = inside the Docker container on the PC.

## Goal

Learn what to check when Nav2 behaves badly, and end with a **pre-flight checklist** (and two
small scripts) that you run before every session.

This chapter is different from the others: **I never proved what went wrong.** The honest
version of the story is more useful than a tidy one, so I tell it as it happened.

## ROS concepts in this chapter

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **A control loop** | The controller repeatedly compares where the robot *should* be with where odometry says it *is*, and sends a new `/cmd_vel`. If the robot cannot do what it is told (weak motors) or the feedback is late (slow messages), the loop oscillates. That oscillation is the "wobble" | `ros2 topic echo /cmd_vel` while the robot drives |
| **Topic rate as a health signal** | A topic that normally runs at a steady rate is a quick check on a whole chain of hardware and network | `ros2 topic hz /scan` |
| **Message type: `BatteryState`** | The robot publishes its battery voltage on `/battery_state` | `ros2 topic echo /battery_state --once` |
| **TF delay as a health signal** | The clock check from Chapter 09 | `ros2 run tf2_ros tf2_monitor` |
| **Hardware problems look like software problems** | A weak battery or poor power can make perfectly correct software misbehave | the checks in Step 13.2 |

## The story in one table

| | |
|---|---|
| **Symptom** | The first time I ran Nav2, the robot managed **short goals** but wobbled slightly. It **refused long-distance goals**, and it **could not go to a goal behind it**, which needs a 'u' turn |
| **What I thought it was** | I could not work it out |
| **What I did** | I restarted the whole system **and** charged the battery a little |
| **Result** | Smooth navigation everywhere, including turning back to a goal behind the robot |
| **What it really was** | **Not proven.** I changed two things at once, so I cannot say which one fixed it |
| **My best guess** | A weak battery, because of the symptoms (below) |
| **Lesson** | Record healthy readings **before** something goes wrong, and change **one thing at a time** |

## Steps

### Step 13.1: The suspects

| Suspect | Why it fits | Why it might not |
|---------|-------------|------------------|
| **Weak battery** | Wobbling, trouble turning on the spot, and giving up on long goals are all what you would expect when the motors cannot deliver the speed the controller asks for. Turning in place and driving far both draw sustained power | I only charged it "a little", so I cannot say it was the main difference |
| **Clock not in sync** | A Pi that has just rebooted starts with a wrong clock until it contacts the time server (Chapter 09). Timestamps that are off by even a second or two can make navigation behave oddly | A badly wrong clock breaks things completely, as in Chapter 08, not only some goals. A small error is possible, but I never measured it |
| **A stale state** | Long sessions can leave the localisation off, the costmaps holding "ghost" obstacles, or discovery in a bad state. A full restart clears all of that | I did not look at any of these before I restarted |
| **Network lag** | `/scan` and `/cmd_vel` travel over wifi. Delays between the PC and the Pi can make a controller twitchy | I never measured the latency |

The honest summary: all four are plausible, the symptoms most resemble a weak battery, and I
cannot rule the others out. I restarted and charged **at the same time**, which destroyed the
evidence.

### Step 13.2: Your diagnostic toolkit

Run these **while the robot is working well**, and write the results down as your baseline.
Later, when something misbehaves, run them again and see which one has moved.

**Battery:**

```bash
# [PC-container]
source /opt/ros/humble/setup.bash
ros2 topic echo /battery_state --once --field voltage
```

A fully charged pack reads noticeably higher than a weak one. The OpenCR board starts beeping
at around 11 V. I would recharge before it gets there, and I would not start a session below
about 11.5 V.

**Power on the Pi:**

```bash
# [Pi]
vcgencmd get_throttled
sudo dmesg | grep -i -E "under-?voltage" | tail
vcgencmd measure_temp
```

`get_throttled` prints a code. `0x0` means all is well. Otherwise, these bits mean:

| Bit | Meaning |
|-----|---------|
| `0x1` | Under-voltage **right now** |
| `0x4` | Throttled **right now** |
| `0x8` | Soft temperature limit **right now** |
| `0x10000` | Under-voltage has happened **since boot** |
| `0x40000` | Throttling has happened since boot |
| `0x80000` | The soft temperature limit has been reached since boot |

Add the values together for the code you see. The "since boot" bits stay until the next reboot.
If `vcgencmd` is missing, it comes with the Raspberry Pi utilities package. Appendix D tells the
power story from the Pi's side.

**Clock:**

```bash
# [Pi]
timedatectl timesync-status
```

```bash
# [PC-container]
ros2 run tf2_ros tf2_monitor
```

The moving frames should show a delay of a fraction of a second (Chapter 09).

**Topic rates:**

```bash
# [PC-container]
ros2 topic hz /scan
ros2 topic hz /odom
ros2 topic hz /tf
```

**Load on the machines:**

```bash
# [Pi]
top -bn1 | head -12
```

```bash
# [PC]
top -bn1 | head -12
```

**Nav2's own messages.** Nav2 prints warnings in its terminal when it cannot make progress or
cannot find a path. Save them instead of watching them scroll past:

```bash
# [PC-container]
ros2 launch turtlebot3_navigation2 navigation2.launch.py map:=/root/maps/lab_map.yaml 2>&1 | tee ~/nav2_run.log
```

`tee` shows the output **and** writes it to `~/nav2_run.log`, so you can read it after something
goes wrong.

### Step 13.3: Write down your baseline

When everything is working, fill in a table like this and keep it with your notes:

| Reading | Healthy value on my robot | How I measured it |
|---------|---------------------------|-------------------|
| `/tf` rate | about 32 Hz | `ros2 topic hz /tf` (Chapter 08) |
| TF delay, moving frames | about -0.04 s | `tf2_monitor` (Chapter 09) |
| `/scan` rate | `about 5 Hz` | `ros2 topic hz /scan` |
| `/odom` rate | `about 10 Hz` | `ros2 topic hz /odom` |
| Battery voltage, charged | `12.4 V` | `/battery_state` |
| `get_throttled` | `0x80000` (hope for `0x0`) | `vcgencmd` on the Pi |
| Pi temperature | `about 50deg C` | `vcgencmd measure_temp` |

I did not have a baseline like this before my first run went wrong, which is exactly the
mistake this chapter is about. Start yours now.

### Step 13.4: The pre-flight checklist

Do these in order, **before every session**.

**Hardware**

- [ ] Battery charged. Voltage above about 11.5 V, and the OpenCR is not beeping
- [ ] USB cables seated: OpenCR, lidar. Lidar spins when the robot starts
- [ ] Floor clear, with space around the robot. No edges the lidar cannot see
- [ ] Wheels respond to a quick teleop test

**Network and time**

- [ ] You know the Pi's current IP (Chapter 02), and `ssh ubuntu@<PI_IP>` works
- [ ] Chrony is running on the PC, and `timedatectl timesync-status` on the Pi names your PC (Chapter 09)
- [ ] `xhost +local:docker` run on the PC (Chapter 07)

**Software, in this order**

- [ ] Start bringup on the Pi, with no red errors (Chapter 04)
- [ ] From the container: `ros2 topic list` shows the robot's topics (Chapter 05)
- [ ] `tf2_monitor` shows small delays for the moving frames
- [ ] Only one of Cartographer or Nav2 is running (Chapter 12)
- [ ] Set the initial pose, rotate in place, and wait for the particle cloud to tighten (Chapter 12)
- [ ] Send a **short** goal first

**While it runs**

- [ ] You stay near the robot, with a teleop terminal ready to press `s`

**When you finish**

- [ ] Stop Nav2, then stop bringup
- [ ] Shut down the Pi cleanly with `sudo shutdown -h now` before cutting the power, so the SD card is not corrupted
- [ ] Put the battery on charge

### Step 13.5: Two small helper scripts

The repo has two scripts in `scripts/` that run the checks from Step 13.2 in one go. They print
the readings and leave the judging to you.

Inside the container, with the robot software running:

```bash
# [PC-container]
bash scripts/preflight-check.sh
```

On the Pi (copy it over with `scp scripts/preflight-check-pi.sh ubuntu@<PI_IP>:~/`):

```bash
# [Pi]
bash ~/preflight-check-pi.sh
```

> **Untested:** I wrote these scripts after the fact, and checked only that they have no
> syntax errors. Read them before running, and check that they work on your setup.

### Step 13.6: The reset ritual

If Nav2 starts misbehaving mid-session, the quickest reliable reset I know is:

1. Stop Nav2 (`Ctrl+C`), then stop bringup on the Pi.
2. Check the battery voltage and the clock sync.
3. Start bringup, then Nav2, and set the initial pose again.

This is what fixed my problem, but because I also charged the battery, I do not know which
part of the reset helped. If it fixes things for you, **write down what you checked first**.

## Checklist

- [ ] You can list the four suspects and say why each might cause wobbling
- [ ] You have a baseline table filled in from a healthy session
- [ ] You know how to read `get_throttled` and the battery voltage
- [ ] You run the pre-flight checklist before each session
- [ ] When something goes wrong, you change **one** thing at a time

## When it broke

This whole chapter is the "when it broke" story. The short version: Nav2 misbehaved, a restart
plus a charge fixed it, and I do not know which one mattered.

| | |
|---|---|
| **Mistake 1** | I had no baseline readings, so I could not tell what had changed |
| **Mistake 2** | I changed two things at once (restart and charge), so I could not tell which one helped |
| **Lesson** | Baseline first, one change at a time, and save the terminal output (Step 13.2) so the clues do not scroll away |

## Recap

- You heard an honest debugging story, including the part where the cause stayed unknown.
- You met **four suspects** for odd navigation, and a toolkit that can tell them apart.
- You saw that **hardware problems** (power) can look like **software problems**.
- You now have a baseline table, a pre-flight checklist and two helper scripts.
- Next: the appendices, and where this guide could go from here.

## Try it yourself (optional)

Run Step 13.2 now, while everything works, and fill in the baseline table. Then deliberately
let the battery run lower than usual (within safe limits, staying near the robot) and repeat the
checks. Which numbers moved first?
