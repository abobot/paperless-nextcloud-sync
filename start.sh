#!/bin/bash

# Check mandatory veriables
if [ -z ${WEBDRIVE_USER} ]; then
  echo "[FAILURE] Webdrive user is not set!"
  exit 1
fi

if [ -z ${WEBDRIVE_PASSWORD} ]; then
  echo "[FAILURE] Webdrive password is not set!"
  exit 1
fi

if [ -z ${WEBDRIVE_URL} ]; then
  echo "[FAILURE] Webdrive url is not set!"
  exit 1
fi

echo "$WEBDRIVE_URL $WEBDRIVE_USER $WEBDRIVE_PASSWORD" >> /etc/davfs2/secrets

# Set optional variables
FOLDER_USER=${SYNC_USERID:-0}
FOLDER_GROUP=${SYNC_GROUPID:-0}
ACCESS_DIR=${SYNC_ACCESS_DIR:-755}
ACCESS_FILE=${SYNC_ACCESS_FILE:-755}

# Set local Variables
locale-gen $LC_ALL


# Create user
if [ $FOLDER_USER -gt 0 ]; then
  useradd webdrive -u $FOLDER_USER -N -G $FOLDER_GROUP
fi

# Mount the webdav drive 
if [ -f "/var/run/mount.davfs/mnt-webdrive.pid" ]; then
  rm /var/run/mount.davfs/mnt-webdrive.pid
fi
mount -t davfs $WEBDRIVE_URL /mnt/webdrive \
-o uid=$FOLDER_USER,gid=$FOLDER_GROUP,dir_mode=$ACCESS_DIR,file_mode=$ACCESS_FILE



echo "Start completed, starting sync-loop"
echo "============================================================================="

while true; do 
  /bin/bash /usr/local/bin/sync.sh
  echo "-----------------------------------------------------------------------------"
  sleep 30s
done
