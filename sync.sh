#!/bin/bash

# Usage: sync.sh SOURCE_DIR WEBDRIVE_DIR REASON

SOURCE_DIR="$1"
WEBDRIVE_DIR="$2"
SYNC_REASON="$3"
DATE_TIME="$(date +%Y-%m-%d)_$(date +%H-%M-%S)"
LOGFILE="/var/log/${DATE_TIME}_${SYNC_REASON}.log"

# 执行 rsync 进行同步，并记录日志
rsync -av --delete "$SOURCE_DIR/" "$WEBDRIVE_DIR/" --log-file="$LOGFILE"

# 输出结果
echo "----------------------------------------------------------------------------------------------------"
echo "[INFO] RESULTS from full synchronization ($LOGFILE):"
cat "$LOGFILE"
echo "----------------------------------------------------------------------------------------------------"
