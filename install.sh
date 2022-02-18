#!/bin/sh

# Terminal colors:
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
NC='\033[0m' # No Color


requirement()
{
  if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Installing requirements: ${CYAN}${1}${NC}"
    apt install -y ${1};    
  fi
}

echo ""
echo "${YELLOW}Setup for Teaching Stats:${NC} Install (v1.0.0)"
echo "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/teaching-stats-setup/blob/main/LICENSE"

echo ""
echo "${LCYAN}Updating repo list:${NC}"
apt update

requirement apache2
requirement python3
requirement libpq-dev python-dev
requirement python3-pip
requirement django==4.0.1
requirement django-allauth==0.47.0
requirement psycopg2-binary==2.9.3

echo ""
echo "${GREEN}Done!${NC}"