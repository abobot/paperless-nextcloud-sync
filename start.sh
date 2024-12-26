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
SOURCE_DIR="/mnt/source"
WEBDRIVE_DIR="/mnt/webdrive"

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



echo "[INFO] Start completed. Start filewatcher"
echo "===================================================================================================="



# setting up filewatcher and actions for for high-performance instant synchronization per-event
# supports renaming and file-move, to preserve existing files in nextcloud (instead of delete+recreate)
inotifywait -m -r -e modify,create,delete,move "$SOURCE_DIR" --format '%e|%w%f|%f' |
while IFS='|' read -r event full_path filename; do
  RELATIVE_PATH="${full_path/${SOURCE_DIR}/''}"
  case "$event" in
    MODIFY|CREATE)
      echo "[ACTION] Detected $event-Event - Copying: $filename"
      cp "$SOURCE_DIR/$RELATIVE_PATH" "$WEBDRIVE_DIR/$RELATIVE_PATH" --verbose
      ;;
    DELETE)
      echo "[ACTION] Detected $event-Event - Deleting: $filename"
      rm "$WEBDRIVE_DIR/$RELATIVE_PATH" --verbose
      ;;
    MOVED_FROM)
      echo "[INFO] Detected $event-Event - File moved: $filename"
      #OLD_PATH_LOCAL="$SOURCE_DIR/$RELATIVE_PATH"
      OLD_PATH_WEBDRIVE="$WEBDRIVE_DIR/$RELATIVE_PATH"
      ;;
    MOVED_TO)
      echo "[ACTION] Detected $event-Event - File moved: $filename"
      #NEW_PATH_LOCAL="$SOURCE_DIR/$RELATIVE_PATH"
      NEW_PATH_WEBDRIVE="$WEBDRIVE_DIR/$RELATIVE_PATH"
      if [[ -n "$OLD_PATH_WEBDRIVE" ]]; then
        mv "$OLD_PATH_WEBDRIVE" "$NEW_PATH_WEBDRIVE" --verbose
        #NEW_PATH_LOCAL=""
        NEW_PATH_WEBDRIVE=""
      else
        echo "[ERROR] Variable \"OLD_PATH_WEBDRIVE\" not set"
      fi
      ;;
    *)
      echo "[ERROR] Unknown $event-Event for $filename"
      echo "Full path: $full_path"
      ;;
  esac
done
