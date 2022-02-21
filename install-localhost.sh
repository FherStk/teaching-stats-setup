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
bbdd='teaching-stats'
pwd=''

apt_req()
{
  if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Installing requirements: ${CYAN}${1}${NC}"
    apt install -y ${1};    
  fi
}

pip_req()
{
  if [ $(pip3 list 2>/dev/null | grep -io -c "${1}") -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Installing requirements: ${CYAN}${1} v${2}${NC}"
    pip3 install ${1}==${2};    
  fi
}

pwd_req()
{
  echo ""
  while true; do
    read -s -p "Set the password for the '${bbdd}' database user:" pwd
    echo
    read -s -p "Set the password (again): " pwd2
    echo
    [ "$pwd" = "$pwd2" ] && break
    echo "Password missmatch, please try again"
  done  
}

bbdd_create()
{
  if [ $(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -c ${bbdd}") -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Creating the '${bbdd}' database:${NC}"
    runuser -l postgres -c "createdb -e ${bbdd}"
  fi
}

bbdd_user(){
  if [ $(runuser -l postgres -c "psql -c "\du ${bbdd}" | cut -d \| -f 1 | grep -c ${bbdd}") -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Creating the '${bbdd}' database user:${NC}"
    pwd_req() #stores in pwd var

    runuser -l postgres -c 'psql -e -c "CREATE USER \"${bbdd}\" WITH PASSWORD '"'"'${pwd}'"'"';"'  #'"'"' means ' -> https://stackoverflow.com/a/1250279
    runuser -l postgres -c 'psql -e -c "ALTER DATABASE \"${bbdd}\" OWNER TO \"${bbdd}\";"'
  fi
}

bbdd_schema(){
  if [ $(runuser -l postgres -c "psql -d \"${bbdd}\" -e -c \"SELECT schema_name FROM information_schema.schemata;\" | cut -d \| -f 1 | grep -c ${1}") -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Creating the '${1}' database schema:${NC}"

    runuser -l postgres -c 'psql -d "${bbdd}" -e -c "CREATE SCHEMA ${1};"'
    runuser -l postgres -c 'psql -e -c "ALTER SCHEMA ${1} OWNER TO \"${bbdd}\";"'
  fi
}

echo ""
echo "${YELLOW}Setup for Teaching Stats:${NC} Install for localhost (v1.0.0)"
echo "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/${bbdd}-setup/blob/main/LICENSE"

echo ""
echo "${LCYAN}Updating repo list:${NC}"
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
echo "${LCYAN}Copying files:${NC}"
cp -r -v ${bbdd} /var/www/${bbdd}

bbdd_create
bbdd_user

bbdd_schema public
bbdd_schema master
bbdd_schema reports

echo ""
echo "${GREEN}Done!${NC}" 