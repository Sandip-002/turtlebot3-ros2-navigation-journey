#!/usr/bin/env bash
# Pre-flight readings from the Pi side. Run ON THE PI, in an SSH session.
# It prints readings; you judge them.
# Untested helper: read it before running, and check that it works on your setup.

echo "== Clock sync (should name your PC as the server) =="
timedatectl timesync-status
date +%T.%N

echo
echo "== Power: get_throttled (0x0 is healthy) =="
if command -v vcgencmd > /dev/null; then
  vcgencmd get_throttled
  vcgencmd measure_temp
else
  echo "vcgencmd not found (it comes with the Raspberry Pi utilities package)"
fi

echo
echo "== Recent under-voltage messages (nothing printed is good) =="
sudo dmesg | grep -i -E "under-?voltage" | tail -n 5

echo
echo "== Load (top 12 lines) =="
top -bn1 | head -12
