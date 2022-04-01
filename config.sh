#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

abort()
{
  #Source: https://stackoverflow.com/a/22224317    
  echo ""
  echo -e "${RED}An error occurred. Exiting...${NC}" >&2
  exit 1
}

options()
{
    echo ""
    echo "Avaliable options are:"
    echo "   survey open: opens the survey season."
    echo "   survey close: closes the survey season."
    echo "   staff add <email> <name> <surname>: adds a new staff member, so he/she will be able to access to the survey results."
    echo "   staff remove <email>: removes a staff member, so he/she will not be able to access to the survey results."
    echo
}

trap 'abort' 0
set -e

FILE="/var/www/teaching-stats/social_app/urls.py"
MODE=${1}
OPTION=${2}

bash ./info.sh "Config"

if [ "$MODE" == "survey" ]; then
    if [ "$OPTION" == "open" ]; then    
        cp -f resources/urls-open.py ${FILE}   
        echo     
        echo -e "${GREEN}Survey seasson is currently open.${NC}"
    elif [ "$OPTION" == "close" ]; then    
        cp -f resources/urls-closed.py ${FILE}
        echo   
        echo -e "${RED}Survey seasson is currently closed.${NC}"
    else
        options
    fi

elif [ "$MODE" == "staff" ]; then
    EMAIL=${3}
    BBDD='teaching-stats'
    
    if [ "$OPTION" == "add" ]; then        
        NAME=${4}
        SURNAME=${5}    
        
        runuser -l postgres -c "psql -d \"${BBDD}\" -c 'INSERT INTO reports.staff (email, name, surname, position) VALUES('\'${EMAIL}\'', '\'${NAME}\'', '\'${SURNAME}\'', (SELECT COUNT(id)+1 FROM reports.staff));'"
        echo -e "${GREEN}Done!${NC}" 
    elif [ "$OPTION" == "remove" ]; then
        runuser -l postgres -c "psql -d \"${BBDD}\" -c 'DELETE FROM reports.staff WHERE email='\'${EMAIL}\'';'"
        echo -e "${GREEN}Done!${NC}" 
    else
        options
    fi
else
    options
fi

trap : 0
echo ""