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

bash ./info.sh "Starting application..."
echo ""

CURRENT=${PWD##*/}
cd /var/www/teaching-stats
python3 manage.py runserver 0.0.0.0:8000  > /dev/null 2>&1 &  #use '0.0.0.0:8000' when running within a container, in order to allow remote connections
PID=$!  

cd ${CURRENT}
rm -f teaching-stats.pid
touch teaching-stats.pid
echo ${PID} > teaching-stats.pid

IPv4=$(hostname -I | cut -d' ' -f1)

echo 
echo "You can access to the survey system through:"
echo "    http://${IPv4}:8000/"
echo "    http://127.0.0.1:8000/"
echo 
echo "You can access to the survey stats through:"
echo "    http://${IPv4}:8000/resultats"
echo "    http://127.0.0.1:8000/resultats"

trap : 0
echo ""