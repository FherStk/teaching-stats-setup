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
    read -s -p "Set the password for the 'teaching-stats' database user:" pwd
    echo
    read -s -p "Set the password (again): " pwd2
    echo
    [ "$pwd" = "$pwd2" ] && break
    echo "Password missmatch, please try again"
  done  
}

echo ""
echo "${YELLOW}Setup for Teaching Stats:${NC} Install for localhost (v1.0.0)"
echo "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/teaching-stats-setup/blob/main/LICENSE"

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
cp -r -v teaching-stats /var/www/teaching-stats

if [ $(runuser -l postgres -c 'psql -lqt | cut -d \| -f 1 | grep -c teaching-stats') -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Creating the 'teaching-stats' database:${NC}"
    runuser -l postgres -c 'createdb -e teaching-stats'
fi

if [ $(runuser -l postgres -c 'psql -c "\du teaching-stats" | cut -d \| -f 1 | grep -c teaching-stats') -eq 0 ];
  then
    echo ""
    echo "${LCYAN}Creating the 'teaching-stats' database user:${NC}"
    pwd_req() #stores in pwd var

    runuser -l postgres -c 'psql -e -c "CREATE USER teaching-stats WITH PASSWORD \"${pwd}\""'
    runuser -l postgres -c 'psql -e -c "ALTER DATABASE teaching-stats OWNER TO teaching-stats"'
fi




#teaching-stats user must be also created and must be the owner of the teaching-stats BBDD
#also the 3 schemas must be created (master, public, reports)
#bbdd populating will do the rest

echo ""
echo "${GREEN}Done!${NC}" 