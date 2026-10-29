# Appendix C: Pre-flight checklist (one page)

Print this page (open it on GitHub and use your browser's Print) and keep it next to the robot.
Every item links back to the chapter that explains it. Tick them in order.

`[Pi]` = SSH session on the robot · `[PC]` = normal PC terminal · `[PC-container]` = inside the Docker container

---

## 1. Before you switch anything on

- [ ] Battery charged: above about **11.5 V**, and the OpenCR is **not beeping** ([13](13-wobbly-navigation-and-the-preflight-checklist.md))
- [ ] OpenCR and lidar USB cables seated, and the lidar is free to spin
- [ ] Floor clear, with space around the robot. **No edges or stairs** the lidar cannot see ([00](00-before-you-start.md))
- [ ] Know the 3 ways to stop it: **`s` in teleop** · **`Ctrl+C`** in the launch terminal · **OpenCR power switch**

## 2. Power on and connect

- [ ] Wait about a minute for the Pi to boot
- [ ] Find the Pi's current IP (it can change after a reboot) ([02](02-getting-the-pi-online.md))
- [ ] `[PC]` `ssh ubuntu@<PI_IP>` works (**with** `ubuntu@`)
- [ ] `[Pi]` `timedatectl timesync-status` names your PC as the time server ([09](09-time-sync-without-internet.md))
- [ ] `[Pi]` and `[PC]`: `date` agrees to within about a second ([08](08-no-transform-and-the-clock.md))

## 3. Start the robot (Pi)

```bash
# [Pi]
source /opt/ros/humble/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
export LDS_MODEL=LDS-01
ros2 launch turtlebot3_bringup robot.launch.py
```

- [ ] No red `ERROR` lines, and the lidar is spinning ([04](04-bringing-up-the-robot.md))

## 4. Start the PC side

```bash
# [PC]
xhost +local:docker
docker start tb3_pc_gui
docker exec -it tb3_pc_gui bash
```

- [ ] `[PC-container]` `ros2 topic list` shows `/scan`, `/odom`, `/cmd_vel`, `/tf` ([05](05-two-machines-one-ros-graph.md))
- [ ] `[PC-container]` `ros2 run tf2_ros tf2_monitor`: moving frames show a delay **well under 1 s** (static frames showing thousands of seconds is normal) ([09](09-time-sync-without-internet.md))
- [ ] `[PC-container]` `ros2 topic echo /battery_state --once --field voltage` looks right

## 5. Pick **one** mode (never both)

**Mapping with Cartographer** ([10](10-mapping-with-cartographer.md), [11](11-saving-the-map.md))

- [ ] Cartographer launched and the map grows in RViz
- [ ] Drive **slowly**, and drive a **loop**
- [ ] **Save the map before stopping Cartographer**, then copy it out of the container

**Navigating with Nav2** ([12](12-navigating-with-nav2.md))

- [ ] **Cartographer is stopped**
- [ ] Nav2 launched with your map file
- [ ] *2D Pose Estimate* set, and the lidar dots **line up with the walls**
- [ ] Rotated in place near a wall, and the particle cloud is **tight**
- [ ] First goal is **short**, in clear white map space

## 6. While it runs

- [ ] You stay **next to the robot**, with a teleop terminal ready to press `s`
- [ ] If it wobbles, refuses goals or stalls: stop, then check battery, clock, `get_throttled` ([13](13-wobbly-navigation-and-the-preflight-checklist.md))

## 7. When you finish

- [ ] Stop Nav2 or Cartographer, then stop bringup
- [ ] `[Pi]` `sudo shutdown -h now`, and wait before cutting power (protects the SD card)
- [ ] Put the battery on charge

---

## My healthy readings

Fill these in once, while everything works, and compare when something goes wrong
([13](13-wobbly-navigation-and-the-preflight-checklist.md)).

| Reading | Command | Healthy value |
|---------|---------|---------------|
| `/tf` rate | `ros2 topic hz /tf` | about 32 Hz (mine) |
| TF delay, moving frames | `tf2_monitor` | about -0.04 s (mine) |
| `/scan` rate | `ros2 topic hz /scan` | about 5 Hz |
| `/odom` rate | `ros2 topic hz /odom` | about 10 Hz |
| Battery voltage, charged | `/battery_state` | 12.4 V |
| Pi power flags | `[Pi]` `vcgencmd get_throttled` | 0x80000 (for `0x0`) |
| Pi temperature | `[Pi]` `vcgencmd measure_temp` | about 50°C |

## If something goes wrong

1. **Stop the robot first.**
2. Check from the bottom up: **power → network → clocks → ROS graph → transforms → application** ([Appendix B](B-troubleshooting-index.md)).
3. Change **one thing at a time**, and note what you changed.
4. Reset ritual: stop Nav2, stop bringup, check battery and clock sync, start bringup, start Nav2, set the pose again.
5. The two helper scripts print the key readings: `scripts/preflight-check.sh` (container) and `scripts/preflight-check-pi.sh` (Pi).
