#!/bin/sh
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


requirement()
{
  if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo "${CYAN}Installing requirements: ${1}${NC}"
    apt-get install ${1};
  fi
}

echo ""
echo "${YELLOW}Setup for Teaching Stats:${NC} Install (v1.0.0)"
echo "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/teaching-stats-setup/blob/main/LICENSE"

echo ""
echo "${CYAN}Updating repo list:${NC}"
apt update

echo ""
requirement apache2

echo ""
requirement python3

# echo ""
# requirement libpq-dev python-dev

# echo ""
# requirement python3-pip

# echo ""
# requirement django==4.0.1

# echo ""
# requirement django-allauth==0.47.0

#echo ""
#requirement psycopg2-binary==2.9.3