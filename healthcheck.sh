#!/bin/bash

# Check if Webdrive is mounted
if mount | grep -q "/mnt/webdrive"; then
  echo "WebDAV is mounted"
else
  echo "[ERROR] WebDAV is not mounted."
  exit 1
fi
echo " | "
# Check if `inotifywait` is still running
if pgrep -x "inotifywait" > /dev/null; then
  echo "Filewatcher is running"
else
  echo "[ERROR] Filewatcher is not running"
  exit 1
fi

exit 0
