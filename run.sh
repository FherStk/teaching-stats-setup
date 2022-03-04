#!/bin/bash
VERSION="0.2.2"
YELLOW='\033[1;33m'
PATH="/var/www/teaching-stats"

#TODO: this should run django but not in the background

#another script called config
#config.sh survey open
#config.sh survey close



cd ${PATH}
python3 manage.py runserver 0.0.0.0:8000  > /dev/null 2>&1 &  #use '0.0.0.0:8000' when running within a container, in order to allow remote connections
PID=$!  

echo ""
echo -e "${YELLOW}Teaching Stats:${NC} (v${VERSION})"
echo -e "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo -e "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo -e "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/teaching-stats-setup/blob/main/LICENSE"
echo 
echo "Teaching stats is running."
echo 
echo "You can access to the survey system through:"
echo "    http://10.102.54.46:8000/"
echo "    http://127.0.0.1:8000/"
echo 
echo "You can access to the survey stats through:"
echo "    http://10.102.54.46:8000/resultats"
echo "    http://127.0.0.1:8000/resultats"

echo "In order to close the application:"
echo "    Run the following command: sudo kill -9 ${PID}"
echo
echo "In order to open the survey season:"
echo "    1. Edit the ${PATH}/social_app/urls.py"
echo "    2. Uncomment line 9"
echo "    2. Comment line 10"
echo
echo "In order to close the survey season:"
echo "    1. Edit the ${PATH}/social_app/urls.py"
echo "    2. Comment line 9"
echo "    2. Uncomment line 10"