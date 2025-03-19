#!/bin/bash

# Set locale
export LC_ALL=en_US.UTF-8

# Check variables
if [[ -z "${WEBDRIVE_USER}" || -z "${WEBDRIVE_URL}" ]]; then
  echo "[ERROR] Missing WEBDRIVE_USER or WEBDRIVE_URL"
  exit 1
fi

if [[ -n "${WEBDRIVE_PASSWORD_FILE}" ]]; then
    WEBDRIVE_PASSWORD=$(cat "${WEBDRIVE_PASSWORD_FILE}")
fi
if [[ -z "${WEBDRIVE_PASSWORD}" ]]; then
    echo "[ERROR] WEBDRIVE_PASSWORD not set!"
    exit 1
fi

echo "$WEBDRIVE_URL $WEBDRIVE_USER $WEBDRIVE_PASSWORD" > /etc/davfs2/secrets

# Mount WebDAV
mount -t davfs "$WEBDRIVE_URL" /mnt/webdrive -o uid=0,gid=0,dir_mode=755,file_mode=755
if [[ $? -ne 0 ]]; then
  echo "[ERROR] Failed to mount $WEBDRIVE_URL"
  exit 1
fi

echo "[INFO] Starting sync..."
/bin/bash sync.sh "/mnt/source" "/mnt/webdrive" "initial-sync" &

# Watch for changes using inotify
inotifywait -m -r -e modify,create,delete,move --exclude '.*\.swp|.*\.tmp' "/mnt/source" --format '%e|%w%f' |
while IFS='|' read -r event full_path; do
  RELATIVE_PATH="${full_path#/mnt/source/}"
  case "$event" in
    MODIFY|CREATE)
      rsync -av "$full_path" "/mnt/webdrive/$RELATIVE_PATH"
      ;;
    DELETE)
      rm -f "/mnt/webdrive/$RELATIVE_PATH"
      ;;
    CREATE,ISDIR)
      mkdir -p "/mnt/webdrive/$RELATIVE_PATH"
      ;;
    DELETE,ISDIR)
      rm -rf "/mnt/webdrive/$RELATIVE_PATH"
      ;;
    MOVED_FROM)
      OLD_PATH_WEBDRIVE="/mnt/webdrive/$RELATIVE_PATH"
      ;;
    MOVED_TO)
      NEW_PATH_WEBDRIVE="/mnt/webdrive/$RELATIVE_PATH"
      if [[ -n "$OLD_PATH_WEBDRIVE" && -e "$OLD_PATH_WEBDRIVE" ]]; then
          mv "$OLD_PATH_WEBDRIVE" "$NEW_PATH_WEBDRIVE"
      else
          rsync -av "$full_path" "/mnt/webdrive/$RELATIVE_PATH"
      fi
      unset OLD_PATH_WEBDRIVE
      ;;
  esac
done &

wait
