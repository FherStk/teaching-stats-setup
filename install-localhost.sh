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
DIR="/var/www/${BBDD}/"
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
  echo ""
  if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then    
    echo -e "${LCYAN}Installing requirements: ${CYAN}${1}${NC}"
    apt install -y ${1};    
  else 
    echo -e "${LCYAN}Requirement ${CYAN}${1}${LCYAN} already satisfied, skipping...${NC}"
  fi
}

pip_req()
{
  echo ""
  if [ $(pip3 list 2>/dev/null | grep -io -c "${1}") -eq 0 ];
  then    
    echo -e "${LCYAN}Installing requirements: ${CYAN}${1} v${2}${NC}"
    pip3 install ${1}==${2};    
  else 
    echo -e "${LCYAN}Requirement ${CYAN}${1}${LCYAN} already satisfied, skipping...${NC}"
  fi
}

copy()
{
  echo ""
  if ! [ -d "$DIR" ]; then    
    echo -e "${LCYAN}Copying files into ${CYAN}${BBDD}${LCYAN}:${NC}"
    cp -r -v "${BBDD}" "/var/www/${BBDD}"
  else
    echo -e "${LCYAN}Files already copied within ${CYAN}${BBDD}${LCYAN}, skipping...${NC}"
  fi
}

pwd_req()
{  
  while true; do
    echo ""
    read -e -sp "Set the password for the ${CYAN}${BBDD}${LCYAN} database user:" PWD
    echo
    read -e -sp "Set the password (again): " PWD2
    echo
    [ "$PWD" = "$PWD2" ] && break
    echo "${RED}Password missmatch, please try again.${NC}"
  done  
}

BBDD_create()
{
  echo ""
  if [ $(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}${BBDD}${LCYAN} database:${NC}"
    runuser -l postgres -c "createdb -e ${BBDD}"
  else
    echo -e "${LCYAN}The database ${CYAN}${BBDD}${LCYAN} already exists, skipping...${NC}"
  fi
}

BBDD_user(){
  echo ""
  if [ $(runuser -l postgres -c "psql -c \"\\du ${BBDD}\" | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}${BBDD}${LCYAN} database user:${NC}"
    pwd_req
    
    runuser -l postgres -c "psql -e -c 'CREATE USER \"${BBDD}\" WITH PASSWORD '\'${PWD}\'';'"
    runuser -l postgres -c "psql -e -c 'ALTER DATABASE \"${BBDD}\" OWNER TO \"${BBDD}\";'"

  else
    echo -e "${LCYAN}The database user ${CYAN}${BBDD}${LCYAN} already exists, skipping...${NC}"
  fi
}

BBDD_schema(){
  echo ""
  if [ $(runuser -l postgres -c "psql -d \"${BBDD}\" -e -c \"SELECT schema_name FROM information_schema.schemata;\" | cut -d \| -f 1 | grep -c ${1}") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}${1}${LCYAN} database schema:${NC}"

    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c \"CREATE SCHEMA ${1};\""
    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'ALTER SCHEMA \"${1}\" OWNER TO \"${BBDD}\";'"

  else
    echo -e "${LCYAN}The database schema ${CYAN}${1}${LCYAN} already exists, skipping...${NC}"
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

copy

BBDD_create
BBDD_user

BBDD_schema public
BBDD_schema master
BBDD_schema reports

trap : 0
echo ""
echo -e "${GREEN}Done!${NC}" 