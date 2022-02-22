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
DIR="/var/www/${BBDD}"
VERSION="0.0.2"
PASS=''

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
    echo -e "${CYAN}Requirement ${LCYAN}${1}${CYAN} already satisfied, skipping...${NC}"
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
    echo -e "${CYAN}Requirement ${LCYAN}${1}${CYAN} already satisfied, skipping...${NC}"
  fi
}

pwd_req()
{  
  while true; do    
    echo -e "Set the password for the ${CYAN}${BBDD}${NC} database user:"
    read -s PASS

    read -sp "Set the password (again): " PASS2
    echo ""

    [ "$PASS" = "$PASS2" ] && break
    echo -e "${RED}Password missmatch, please try again.${NC}"
    echo ""
  done  
}

bbdd_create()
{
  echo ""
  if [ $(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}${BBDD}${LCYAN} database:${NC}"
    runuser -l postgres -c "createdb -e ${BBDD}"
  else
    echo -e "${CYAN}The database ${LCYAN}${BBDD}${CYAN} already exists, skipping...${NC}"
  fi
}

bbdd_user(){
  echo ""
  if [ $(runuser -l postgres -c "psql -c \"\\du ${BBDD}\" | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}${BBDD}${LCYAN} database user:${NC}"
    pwd_req
    
    runuser -l postgres -c "psql -e -c 'CREATE USER \"${BBDD}\" WITH PASSWORD '\'${PASS}\'';'"
    runuser -l postgres -c "psql -e -c 'ALTER DATABASE \"${BBDD}\" OWNER TO \"${BBDD}\";'"

  else
    echo -e "${CYAN}The database user ${LCYAN}${BBDD}${CYAN} already exists, skipping...${NC}"
  fi
}

bbdd_schema(){
  echo ""
  if [ $(runuser -l postgres -c "psql -d \"${BBDD}\" -e -c \"SELECT schema_name FROM information_schema.schemata;\" | cut -d \| -f 1 | grep -c ${1}") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}${1}${LCYAN} database schema:${NC}"

    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c \"CREATE SCHEMA ${1};\""
    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'ALTER SCHEMA \"${1}\" OWNER TO \"${BBDD}\";'"

  else
    echo -e "${CYAN}The database schema ${LCYAN}${1}${CYAN} already exists, skipping...${NC}"
  fi
}

copy_files()
{
  echo ""
  if ! [ -d "$DIR" ]; then    
    echo -e "${LCYAN}Copying files into ${CYAN}${BBDD}${LCYAN}:${NC}"
    cp -r -v "${BBDD}" "/var/www/${BBDD}"
  else
    echo -e "${CYAN}Files already copied within ${LCYAN}${BBDD}${CYAN}, skipping...${NC}"
  fi
}

setup_files()
{
  MARK="$DIR/home/status.done"
  FILE="$DIR/home/settings.py"

  echo ""
  if ! [ -f "$MARK" ]; then    
    echo -e "${LCYAN}Setting up the django file ${CYAN}${FILE}${LCYAN}:${NC}"
    echo "Setting up database name..."
    sed -i "s/'YOUR-DATABASE'/'${BBDD}'/g" ${FILE}

    echo "Setting up database user..."
    sed -i "s/'YOUR-USER'/'${BBDD}'/g" ${FILE}

    if [ ${PASS} = ""];
    then    
      #if the bbdd already exists, the password must be provided
      echo -e "Please, provide the password for the ${CYAN}${BBDD}${NC} database user:"
      read -s PASS          
    fi
    
    echo "Setting up database password..."
    sed -i "s/'YOUR-PASSWORD'/'${PASS}'/g" ${FILE}

    echo "Setting up database host..."
    sed -i "s/'YOUR-HOST'/'localhost'/g" ${FILE}

    echo "Setting up database port..."
    sed -i "s/'YOUR-PORT'/'5432'/g" ${FILE}

    touch $MARK
  else
    echo -e "${CYAN}Django file ${LCYAN}${FILE}${CYAN} setup already done, skipping...${NC}"
  fi
}

setup_django()
{
  echo ""  
  echo -e "${LCYAN}Setting up the ${CYAN}${BBDD}${LCYAN} django instance:${NC}"
  
  CURRENT=${PWD##*/}
  
  cd ${DIR}
  python3 manage.py makemigrations --noinput
  
  echo ""  
  python3 manage.py migrate --noinput  
  python3 dbsetup.py
  python3 manage.py collectstatic --noinput
  
  echo ""    
  echo -e "${LCYAN}Setting up the ${CYAN}${BBDD}${LCYAN} django superuser:${NC}"
  if [ ${PASS} = ""];
  then    
    #if the bbdd already exists, the password must be provided
    echo -e "Please, provide the password for the ${CYAN}${BBDD}${NC} django superuser:"
    read -s PASS          
  fi
  
  DJANGO_SUPERUSER_USERNAME=${BBDD} \
  DJANGO_SUPERUSER_PASSWORD=${PASS} \
  DJANGO_SUPERUSER_EMAIL= \
  python3 manage.py createsuperuser --noinput

  cd $HOME/${CURRENT}
}

trap 'abort' 0
set -e

echo ""
echo -e "${YELLOW}Setup for Teaching Stats:${NC} Install for localhost (v${VERSION})"
echo -e "${YELLOW}Copyright © 2022:${NC} Marcos Alcocer Gil"
echo -e "${YELLOW}Copyright © 2022:${NC} Fernando Porrino Serrano"
echo -e "${YELLOW}Under the AGPL license:${NC} https://github.com/FherStk/${BBDD}-setup/blob/main/LICENSE"

echo ""
echo -e "${LCYAN}Updating repo list:${NC}"
apt update

apt_req apache2
apt_req python3
apt_req libpq-dev 
apt_req python-dev-is-python2
apt_req python3-pip
apt_req postgresql
apt_req postgresql-contrib

pip_req django 4.0.1
pip_req django-allauth 0.47.0
pip_req psycopg2-binary 2.9.3

bbdd_create
bbdd_user

bbdd_schema public
bbdd_schema master
bbdd_schema reports

copy_files
setup_files
setup_django

trap : 0
echo ""
echo -e "${GREEN}Done!${NC}" 