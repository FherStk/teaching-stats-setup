#!/bin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color

abort()
{
  #Source: https://stackoverflow.com/a/22224317    
  echo ""
  echo -e "${RED}An error occurred. Exiting...${NC}" >&2
  exit 1
}

trap 'abort' 0
set -e

bash ./info.sh "Stopping application..."
PID=$(head -n 1 teaching-stats.pid)

rm teaching-stats.pid
kill -9 ${PID}
echo "Application stopped."

trap : 0
echo ""