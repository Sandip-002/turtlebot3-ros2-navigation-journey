# Chapter 09: Time sync without internet

> **Command tags:** `[Pi]` = SSH session on the robot, `[PC]` = normal PC terminal,
> `[PC-container]` = inside the Docker container on the PC.

## Goal

Make the Pi's clock agree with the PC's clock, **without internet**, and keep it that way after
every reboot, so the transform problems from [Chapter 08](08-no-transform-and-the-clock.md)
do not come back.

## ROS concepts in this chapter

This chapter is about operating-system time, but ROS stands directly on top of it.

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **ROS time = system clock** | On a real robot, nodes stamp their messages with the machine's own clock. ROS does not synchronise clocks between machines. (Only with `use_sim_time:=true`, for simulators, does a node use a different clock) | `date` |
| **TF delay** | How old a transform looks to the machine reading it. The best single number for "do my clocks agree?" | `ros2 run tf2_ros tf2_monitor` |
| **Static vs dynamic transforms** *(revisited)* | `/tf_static` is published once at startup, so its "delay" just grows with the age of the robot software. Only the dynamic frames tell you about clock agreement | see Step 9.5 |

Time words you need:

| Word | Meaning |
|------|---------|
| **NTP** | Network Time Protocol: how computers ask each other for the time. It works on any local network, **no internet required**, as long as one machine on it is willing to be the time source |
| **Time server** | The machine others ask. Here: your PC, running **chrony** |
| **Time client** | The machine that asks. Here: the Pi, running **systemd-timesyncd**, which Ubuntu already includes |

## Before you start

- [ ] Chapter 08 is done: you know the Pi's clock is the problem
- [ ] The Pi and the PC are on the same network (Chapter 02)
- [ ] The PC's own clock is **correct**. Everything else will copy it, right or wrong

## Steps

### Step 9.1: The quick fix: set the Pi's clock by hand

The obvious first move is to copy the PC's time onto the Pi:

```bash
# [PC]
ssh -t ubuntu@<PI_IP> "sudo date -s '$(date '+%F %T')'"
```

SSH asks for the Pi's password. Then restart the robot software on the Pi (stop it with `Ctrl+C`,
and run `ros2 launch turtlebot3_bringup robot.launch.py` again), and measure:

```bash
# [PC-container]
source /opt/ros/humble/setup.bash
ros2 run tf2_ros tf2_monitor
```

**What I saw:** an average delay of **about 42 seconds** and a maximum of **about 111 seconds**.
That is far better than 195 days, but far from the fraction of a second a healthy system shows.

### Step 9.2: Find out why it is still wrong

I compared the two clocks, down to fractions of a second:

```bash
# [Pi]
date +%T.%N
```

```bash
# [PC]
date +%T.%N
```

```text
PC:  15:44:01.1367
Pi:  15:43:18.429
```

The Pi was still about **43 seconds behind**. Next I looked at the Pi's clock settings:

```bash
# [Pi]
timedatectl
```

```text
Local time: Mon 2026-10-05 15:43:45 +08
RTC time: n/a
System clock synchronized: no
NTP service: inactive
```

Two things stand out. `RTC time: n/a` means the Pi has no hardware clock, and
`NTP service: inactive` means nothing is correcting it. Next I checked whether the Pi's clock
was **running at the right speed**: I ran `date` on the Pi, waited 10 seconds by a stopwatch,
and ran `date` again. The difference was exactly 10 seconds. So the clock ticks correctly, it
was simply **set to the wrong time**.

### Step 9.3: The mistake in my own clock fixing process

The mistake was in the command from Step 9.1. Look at the order of events:

1. `$(date '+%F %T')` is evaluated **on the PC, immediately**, when I press Enter. The time is
   now frozen into the terminal window but the clock still ticking.
2. Then SSH connects (as in Step 9.1) and **asks for the Pi's login password**.
3. I type the password. This takes some seconds.
4. The Pi sets its clock to the frozen time from step 1.

Every second spent at the password prompt becomes an error in the Pi's clock. Typing the
password, plus the sudo prompt, added up to about 43 seconds.

My first attempt to fix this was to read the `sudo` password **before** reading the time. That
did not help, because the delay was at the **SSH login** prompt, not the `sudo` one. I only
found out because I looked at what I was typing and when.

**Lesson:** copying the time by hand always adds the delay between "read" and "set". The cure
is to take humans out of the loop: let the Pi **ask** for the time itself, over and over.

### Step 9.4: Turn the PC into a time server

On the PC:

```bash
# [PC]
hostname -I
```

Note your PC's address on the lab network. This is `<PC_IP>`. Install **chrony**, a time
service that can also act as a server. On Ubuntu it replaces the default `systemd-timesyncd`
on the PC:

```bash
# [PC]
sudo apt install chrony
```

Add two lines to its configuration. Replace `<LAN_SUBNET>` with your network, for example
`192.168.1.0/24`:

```bash
# [PC]
echo "allow <LAN_SUBNET>" | sudo tee -a /etc/chrony/chrony.conf
echo "local stratum 10" | sudo tee -a /etc/chrony/chrony.conf
sudo systemctl restart chrony
```

| Line | Meaning |
|------|---------|
| `allow <LAN_SUBNET>` | Let machines on my local network ask this PC for the time |
| `local stratum 10` | Keep serving time **even when this PC has no internet** (it vouches for its own clock) |

If you use the `ufw` firewall (check with `sudo ufw status`), let NTP through:

```bash
# [PC]
sudo ufw allow from <LAN_SUBNET> to any port 123 proto udp
```

### Step 9.5: Tell the Pi to ask the PC

On the Pi, edit `/etc/systemd/timesyncd.conf`:

```bash
# [Pi]
sudo nano /etc/systemd/timesyncd.conf
```

Under the `[Time]` heading, set:

```ini
[Time]
NTP=<PC_IP>   #Put your actual PC IP here
```

Make sure the line does not start with `#`. Then turn time sync on and restart the service:

```bash
# [Pi]
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd
```

Wait about 30 seconds and check:

```bash
# [Pi]
timedatectl timesync-status
date +%T.%N
```

```bash
# [PC]
date +%T.%N
```

**You should see** the Pi's `timesync-status` naming your PC as its server, and the two `date`
outputs within about a second of each other. (Running the two `date` commands by hand always
has a little human delay in it. The real check is the next step.)

> I made this edit with a one-line `sed` command, which does the same thing as the manual edit.

### Step 9.6: Restart the robot software and measure again

Changing the clock while ROS nodes are running can confuse nodes that use timers, so restart
bringup after the clock has settled:

```bash
# [Pi]
# stop bringup with Ctrl+C, then:
ros2 launch turtlebot3_bringup robot.launch.py
```

```bash
# [PC-container]
ros2 run tf2_ros tf2_monitor
```

**What I saw** (shortened):

```text
Frame: base_footprint, ... Average Delay: -0.0357188, Max Delay: 0
Frame: wheel_left_link, ... Average Delay: -0.0382625, Max Delay: 0
Frame: wheel_right_link, ... Average Delay: -0.0382593, Max Delay: 0
Frame: base_link, ... Average Delay: 2994.35, Max Delay: 2994.35
Frame: base_scan, ... Average Delay: 2994.35, Max Delay: 2994.35
Frame: camera_link, ... Average Delay: 2994.35, Max Delay: 2994.35
Frame: imu_link, ... Average Delay: 2994.35, Max Delay: 2994.35
All Broadcasters:
Node: <no authority available> 32.2618 Hz, Average Delay: -0.0356727 Max Delay: 0
```

How to read this:

- **The moving frames** (`base_footprint`, the two wheels) have a delay of about **-0.036 s**.
  That is the number that matters: the clocks agree to within a few hundredths of a second.
  A *negative* delay just means the Pi's stamp is a hair ahead of the PC's clock.
- **The other frames show 2994 seconds**, about 50 minutes. That looks alarming but is
  **normal**. Those are **static** transforms (the lidar, the IMU and the camera are bolted to
  the robot), published once when the robot software started. Their "delay" is simply how long
  ago that was. Tools treat static transforms as valid at all times, so they cause no trouble.
- The overall broadcaster rate is about **32 Hz**, as in Chapter 08.

Then open RViz with Cartographer (Chapter 10) and check that the TF display is green.

### Step 9.7: Things that can break it again

| Situation | What happens | What to do |
|-----------|--------------|------------|
| The Pi **reboots** | Its clock starts wrong again until it reaches the PC, usually within a minute | Check `timedatectl timesync-status` before starting bringup |
| The Pi **changes network** (for example, from the hotspot back to the lab wifi) | Time sync may not recover by itself. After I moved the Pi back to the lab wifi, I had to restart the service | `sudo systemctl restart systemd-timesyncd` on the Pi |
| The **PC's IP address changes** (DHCP) | The Pi keeps asking the old address | Give the PC a DHCP reservation in your router, or update `NTP=` on the Pi |
| The **PC's clock is wrong** | The Pi faithfully copies the wrong time | Keep the PC's own clock correct (chrony does this whenever the PC has internet) |

> **If your network does have internet**, you do not need any of this: Ubuntu's default time
> servers keep the Pi right on their own, as soon as the Pi can reach them. The PC-as-time-server
> setup is for networks like my lab's, with no internet.

## Checklist

- [ ] `chrony` is running on the PC (`systemctl status chrony`)
- [ ] The Pi's `timesync-status` names your PC as its server
- [ ] `tf2_monitor` shows a delay under about 0.1 s for `base_footprint` and the wheel frames
- [ ] You understand why static frames can show a large "delay"
- [ ] You know the first two things to check after a reboot or network change
- [ ] You can explain why setting the clock by hand over SSH adds an error

## When it broke

### Case 1: the clock was still 43 seconds off after setting it

| | |
|---|---|
| **Symptom** | After setting the Pi's clock from the PC, `tf2_monitor` still showed delays of 42 and 111 seconds |
| **What I thought it was** | The clock was not set at all, or was set wrongly |
| **How I tested it** | Compared `date +%T.%N` on both machines (a 43-second gap), checked `timedatectl`, and timed the Pi's clock for 10 seconds against a stopwatch |
| **What it really was** | The command read the PC's time first and then waited at the SSH password prompt. The time spent typing became the error |
| **Fix** | Stop copying the time by hand. Run a time server on the PC and let the Pi ask for it (Steps 9.4 and 9.5) |
| **Lesson** | When a hand-set value is off by about as long as the manual steps took, look for a delay between reading and writing |

### Case 2: time sync stopped after changing network

| | |
|---|---|
| **Symptom** | After moving the Pi from the phone hotspot back to the lab wifi, the clocks no longer agreed |
| **What it really was** | I did not find out. The time service did not pick up the new network by itself |
| **Fix** | Restarting `systemd-timesyncd` on the Pi fixed it |
| **Lesson** | After any network change, run `timedatectl timesync-status` before trusting the clock |

## Recap

- You tried the quick fix, measured it, and found that hand-setting a clock over SSH adds the time you spend typing the login password.
- You made your PC the **time server** and the Pi a **client**, with no internet needed.
- You verified with `tf2_monitor`: the moving frames went from a 195-day delay to about -0.036 s.
- You learned how to read **static** versus **dynamic** transform delays.
- Next: use this working robot to build a map with Cartographer.

## Try it yourself (optional)

Reboot the Pi and watch it recover: after it is back, run `timedatectl timesync-status` every
few seconds. How long does it take to name your PC as its server and settle?
