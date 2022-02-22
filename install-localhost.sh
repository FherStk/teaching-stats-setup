#!/bin/bash

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
BBDD='teaching-stats'
PWD=''

abort()
{
  #Source: https://stackoverflow.com/a/22224317    
  echo ""
  echo -e "${RED}An error occurred. Exiting...${NC}" >&2
  exit 1
}

apt_req()
{
  if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo ""
    echo -e "${LCYAN}Installing requirements: ${CYAN}${1}${NC}"
    apt install -y ${1};    
  fi
}

pip_req()
{
  if [ $(pip3 list 2>/dev/null | grep -io -c "${1}") -eq 0 ];
  then
    echo ""
    echo -e "${LCYAN}Installing requirements: ${CYAN}${1} v${2}${NC}"
    pip3 install ${1}==${2};    
  fi
}

pwd_req()
{  
  while true; do
    echo ""
    read -sp "Set the password for the '${BBDD}' database user:" PWD
    echo
    read -sp "Set the password (again): " PWD2
    echo
    [ "$PWD" = "$PWD2" ] && break
    echo "Password missmatch, please try again"
  done  
}

BBDD_create()
{
  if [ $(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then
    echo ""
    echo -e "${LCYAN}Creating the '${BBDD}' database:${NC}"
    runuser -l postgres -c "createdb -e ${BBDD}"
  fi
}

BBDD_user(){
  if [ $(runuser -l postgres -c "psql -c \"\\du ${BBDD}\" | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then
    echo ""
    echo -e "${LCYAN}Creating the '${BBDD}' database user:${NC}"
    pwd_req
    
    runuser -l postgres -c "psql -e -c 'CREATE USER \"${BBDD}\" WITH PASSWORD '\'${PWD}\'';'"
    runuser -l postgres -c "psql -e -c 'ALTER DATABASE \"${BBDD}\" OWNER TO \"${BBDD}\";'"
  fi
}

BBDD_schema(){
  if [ $(runuser -l postgres -c "psql -d \"${BBDD}\" -e -c \"SELECT schema_name FROM information_schema.schemata;\" | cut -d \| -f 1 | grep -c ${1}") -eq 0 ];
  then
    echo ""
    echo -e "${LCYAN}Creating the '${1}' database schema:${NC}"

    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c \"CREATE SCHEMA ${1};\""
    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'ALTER SCHEMA \"${1}\" OWNER TO \"${BBDD}\";'"
  fi
}

trap 'abort' 0
set -e

echo ""
echo -e "${YELLOW}Setup for Teaching Stats:${NC} Install for localhost (v1.0.0)"
echo -e "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo -e "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo -e "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/${BBDD}-setup/blob/main/LICENSE"

echo ""
echo -e "${LCYAN}Updating repo list:${NC}"
apt update

apt_req apache2
apt_req python3
apt_req libpq-dev python-dev
apt_req python3-pip
apt_req postgresql

pip_req django 4.0.1
pip_req django-allauth 0.47.0
pip_req psycopg2-binary 2.9.3

echo ""
echo -e "${LCYAN}Copying files:${NC}"
cp -r -v "${BBDD}" "/var/www/${BBDD}"

BBDD_create
BBDD_user

BBDD_schema public
BBDD_schema master
BBDD_schema reports

trap : 0
echo ""
echo -e "${GREEN}Done!${NC}" 