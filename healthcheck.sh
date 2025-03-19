#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 检查 WebDAV 挂载状态
if findmnt -r /mnt/webdrive > /dev/null; then
  echo -e "${GREEN}[INFO] WebDAV is mounted.${NC}"
else
  echo -e "${RED}[ERROR] WebDAV is not mounted!${NC}"
  exit 1
fi

# 检查 `inotifywait` 进程是否在运行
if pgrep -f "inotifywait" > /dev/null; then
  echo -e "${GREEN}[INFO] Filewatcher is running.${NC}"
else
  echo -e "${RED}[ERROR] Filewatcher is not running!${NC}"
  exit 1
fi

exit 0
