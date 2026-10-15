# Chapter 02: Getting the Pi online

> **Command tags:** `[Pi]` = on the robot's Pi (its own keyboard and monitor for now, SSH later),
> `[PC]` = normal PC terminal, `[PC-container]` = inside the Docker container on the PC.

## Goal

Put the Raspberry Pi on your wifi network and log in to it from your PC over SSH, so you can
put the monitor and keyboard away and drive the robot from your desk.

## ROS concepts in this chapter

This chapter is about networking, not ROS itself, but ROS 2 depends on it completely.

| Concept | What it is here | How to see it yourself |
|---------|-----------------|------------------------|
| **IP address and DHCP** | The router hands the Pi an address (like `192.168.1.x`) when it joins. It can change after a reboot | `ip -br a` |
| **Same network** | The Pi and the PC must be on the same local network for ROS 2 to connect them | `ip -br a` on both, compare the first three numbers of the address |
| **SSH** | A remote terminal on the Pi. Every `[Pi]` command in this guide is run through it | `ssh ubuntu@<PI_IP>` |
| **ROS graph over a network** *(preview)* | In Chapter 05 you will see that nodes on different machines on the same network find each other automatically. That only works if this chapter is done properly | |

## Before you start

- [ ] Chapter 01 is done and you can log in on the Pi's keyboard and monitor
- [ ] You know your wifi name (SSID) and password
- [ ] Your PC is connected to the **same router** (wifi or cable)

## Steps

### Step 2.1: See what the Pi has now

```bash
# [Pi]
ip -br a
ls /etc/netplan/
```

`ip -br a` lists the network interfaces. Look for `wlan0` (the wifi). If it has no
`192.168...` style address, the Pi is not connected.

On Ubuntu images for the Pi, network settings live in **netplan** files in `/etc/netplan/`.
They are YAML files, which means **indentation matters and you must use spaces, not tabs**.

### Step 2.2: Write the wifi settings

> This is a generic example, not a copy of my file. Use your own SSID and password in place
> of the placeholders.

```bash
# [Pi]
sudo nano /etc/netplan/60-wifi.yaml
```

```yaml
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      access-points:
        "<LAB_WIFI_SSID>":
          password: "<LAB_WIFI_PASSWORD>"
```

Keep the quotation marks, and keep the spacing exactly as shown.

> Some Ubuntu images create `/etc/netplan/50-cloud-init.yaml` automatically, and its header warns
> that edits may not survive a reboot. Using your own separate file avoids that problem.
> If the existing file already defines `wlan0`, move that definition into your file or
> remove it so the two do not conflict.

Netplan files hold a password, so restrict who can read the file:

```bash
# [Pi]
sudo chmod 600 /etc/netplan/60-wifi.yaml
```

### Step 2.3: Check the file and apply it

```bash
# [Pi]
sudo netplan generate
sudo netplan try
```

- `netplan generate` checks your file for syntax mistakes without applying it.
- `netplan try` applies the settings and **rolls back automatically** after 120 seconds unless
  you press Enter. That protects you from locking yourself out.

If `try` succeeds and you press Enter, the settings are kept.

### Step 2.4: Verify you are online

```bash
# [Pi]
ip -br a
ip route | grep default
ping -c 3 <ROUTER_IP>
```

**You should see:** `wlan0` with an address like `192.168.1.x`, a default route through your
router, and ping replies. Write the Pi's address down; this is your `<PI_IP>`.

Now check the PC is on the same network:

```bash
# [PC]
hostname -I
ping -c 3 <PI_IP>
```

The first three numbers of the PC's address should match the Pi's, and the ping should work.

### Step 2.5: Log in over SSH

```bash
# [PC]
ssh ubuntu@<PI_IP>
```

The first time, SSH asks whether you trust this machine. Type `yes`. Then enter the Pi's
password.
> **Always include the username.** If you type `ssh <PI_IP>` without `ubuntu@`, SSH tries to log in
> with your **PC's** username, and the Pi's correct password will be rejected. If the right
> password fails, check the username first.

You are now on the Pi from your PC, and the prompt should show the Pi's hostname.

**From now on, every `[Pi]` command in this guide runs in this SSH session.**
You can disconnect the monitor and keyboard.

### Step 2.6 (optional): Add a second network for internet access

My lab router had **no internet**, which is a problem when you need `apt install` on the Pi
(Chapter 01, Step 1.4b) or when you need a correct clock (Chapter 09). My workaround was to
add my **phone's hotspot** as a second network in the same netplan file:

```yaml
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      access-points:
        "<LAB_WIFI_SSID>":
          password: "<LAB_WIFI_PASSWORD>"
        "<PHONE_HOTSPOT_SSID>":
          password: "<HOTSPOT_PASSWORD>"
```

```bash
# [Pi]
sudo netplan generate
sudo netplan try
```

With the hotspot switched on, the Pi joined it and `sudo apt update` worked. Afterwards I
switched back to the lab wifi. If both networks are in range, the Pi may pick either, so turn
the hotspot off when you are done.

> The Raspberry Pi 3 Model B only supports 2.4 GHz wifi. If your phone or router offers only
> 5 GHz, the Pi will not see it.

## Checklist

- [ ] `ip -br a` on the Pi shows an address on `wlan0`
- [ ] The PC and the Pi share the first three numbers of their addresses
- [ ] `ssh ubuntu@<PI_IP>` from the PC logs you in
- [ ] You wrote down the Pi's IP, and you know it can change after a reboot
- [ ] No password or wifi key is saved in any file you plan to publish

## When it broke

### Case 1: the Pi's IP address changed

| | |
|---|---|
| **Symptom** | After a reboot, the address I had been using for the Pi was no longer right. It had moved from `192.168.1.102` to `192.168.1.100` |
| **What I thought it was** | The router's password is changed by someone |
| **What it really was** | The router hands out addresses by DHCP, so the Pi is not guaranteed the same one each time |
| **Fix** | Read the new address on the Pi with `ip -br a` and use it in the `ssh` command |
| **Lesson** | Check the address at the start of every session. For a permanent fix, make a **DHCP reservation** for the Pi's MAC address in your router's settings, if you have access |

### Case 2: the SSH login showed "Incorrect password, retry login"

| | |
|---|---|
| **Symptom** | Whatever password I try to login through SSH, failed |
| **What I thought it was** | Someone changed the Pi's password |
| **How I tested it** | I had no clue to test it |
| **What it really was** | Instead of using the command `ssh ubuntu@<PI_IP>`, I typed `ssh <PI_IP>`. As a result it asked for password like: `Password for <PC_HOST_NAME>@<PI_IP>`rather than `Password for <ubuntu>@<PI_IP>` |
| **Fix** | I corrected the syntax by confirming from claude AI |
| **Lesson** | Check the file for syntax mistakes |

**Common causes to check if you hit this too:** a typo in the SSID or password, tabs instead
of spaces in the YAML, the wrong interface name, a 5 GHz-only network on a Pi that only
supports 2.4 GHz, and a second netplan file that also defines `wlan0`.



## Recap

- You put the Pi on your network and logged in over SSH, so the robot no longer needs a screen.
- You saw that ROS 2 relies on the network: same subnet, working addresses.
- You learned two habits: check the Pi's IP every session, and never commit wifi passwords.
- Next: set up Docker on the PC so it can run ROS 2 Humble, matching the Pi.

## A note about the clock

Without internet, the Pi had the **wrong date** (it showed May 2026 when the real date was
October 2026). I noticed this later, during bringup (Chapter 04), and wrote it down as "fix
later, not blocking". That turned out to matter: the wrong clock caused the transform errors in
[Chapter 08](08-no-transform-and-the-clock.md).
