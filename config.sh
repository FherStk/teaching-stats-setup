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

options()
{
    echo ""
    echo "Avaliable options are:"
    echo "   survey open: opens the survey season."
    echo "   survey close: closes the survey season."
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
        mv -f resources/urls-open.py ${FILE}        
        echo "Survey seasson is currently open."
    elif [ "$OPTION" == "close" ]; then    
        mv -f resources/urls-closed.py ${FILE}
        echo "Survey seasson is currently closed."
    else
        options
    fi

else
    options
fi


trap : 0
echo ""