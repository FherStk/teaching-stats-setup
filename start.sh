#!/bin/bash
RED='\033[0;31m'
CYAN='\033[0;36m'
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

IPv4=$(hostname -I | cut -d' ' -f1)

echo 
echo -e "${CYAN}You can access to the survey system through:${NC}"
echo "    http://${IPv4}:8000/"
echo "    http://127.0.0.1:8000/"
echo "    http://teaching-stats.com:8000/"
echo 
echo -e "${CYAN}You can access to the survey stats through:${NC}"
echo "    http://${IPv4}:8000/resultats"
echo "    http://127.0.0.1:8000/resultats"
echo "    http://teaching-stats.com:8000/resultats"
echo 

cd /var/www/teaching-stats
python3 manage.py runserver 0.0.0.0:8000

trap : 0
echo ""