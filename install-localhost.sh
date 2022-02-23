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
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
NC='\033[0m' # No Color
BBDD='teaching-stats'
DIR="/var/www/${BBDD}"
HOST='127.0.0.1'
URL="http://${HOST}:8000"
VERSION="0.0.3"
PASS=''
EMAIL=''

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
    echo -e "${ORANGE}Please, provide the password for the ${CYAN}${BBDD}${ORANGE} ${1}:${NC}"
    read -s PASS

    echo -e "${ORANGE}Set the password (again):${NC}"
    read -s PASS2
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
    pwd_req "postgresql database user"
    
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
  MARK="$DIR/setup-files.done"
  FILE="$DIR/home/settings.py"

  echo ""
  if ! [ -f "$MARK" ]; then    
    echo -e "${LCYAN}Setting up the initial django data within ${CYAN}${FILE}${LCYAN}:${NC}"
    echo "Setting up database name..."
    sed -i "s/'YOUR-DATABASE'/'${BBDD}'/g" ${FILE}

    echo "Setting up database user..."
    sed -i "s/'YOUR-USER'/'${BBDD}'/g" ${FILE}

    if [ ${PASS} = ""];
    then    
      #if the bbdd already exists, the password must be provided
      pwd_req "postgresql database user"              
    fi
    
    echo "Setting up database password..."
    sed -i "s/'YOUR-PASSWORD'/'${PASS}'/g" ${FILE}

    echo "Setting up database host..."
    sed -i "s/'YOUR-HOST'/'localhost'/g" ${FILE}

    echo "Setting up database port..."
    sed -i "s/'YOUR-PORT'/'5432'/g" ${FILE}    
    
    touch $MARK
  else
    echo -e "${CYAN}Django file ${LCYAN}${FILE}${CYAN} setup for the initial data is already done, skipping...${NC}"
  fi
}

setup_django()
{
  MARK="$DIR/setup-django.done"

  echo ""  
  if ! [ -f "$MARK" ]; then    
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
    pwd_req "django superuser"
    fi
    
    echo -e "${ORANGE}Please, provide the email for the ${CYAN}${BBDD}${ORANGE} django superuser:${NC}"
    read EMAIL          
    echo ""

    DJANGO_SUPERUSER_PASSWORD=${PASS} \
    python3 manage.py createsuperuser --noinput --username ${BBDD} --email ${EMAIL}

    cd $HOME/${CURRENT}
    touch $MARK
  else
    echo -e "${CYAN}Django instance ${LCYAN}${FILE}${CYAN} setup already done, skipping...${NC}"
  fi
}

setup_gauth(){
  MARK="$DIR/setup-gauth.done"
  
  echo ""  
  if ! [ -f "$MARK" ]; then        
    
    echo -e "${ORANGE}Please, provide the ${CYAN}current localhost IP address${ORANGE} [127.0.0.1]:${NC}"
    read -s IP
    if ! [ -z "$IP" ]; then    
      HOST=${IP}
    fi

    if [ -z "$EMAIL" ]; then    
      EMAIL="<your email>"
    fi

    echo -e "${LCYAN}Setting up Google Authentication:${NC}"
    echo -e "    1. Visit the Google Developers Console at ${CYAN}https://console.developers.google.com/projectcreate${NC} and log in with your Google account."
    echo -e "        1.1. Project name: ${CYAN}${BBDD}${NC}"
    echo -e "        1.2. Leave the other fields with its default values."
    echo -e "        1.3. Press the ${CYAN}create${NC} button."
    echo ""
    echo -e "    2. At the left panel, go to: ${CYAN}API and services -> OAuth consent screen${NC}"
    echo -e "        2.1. User type: ${CYAN}external${NC}"
    echo -e "        2.2. Press the ${CYAN}create${NC} button."
    echo ""
    echo -e "    3. Add the following app information:"
    echo -e "        3.1. App name: ${CYAN}${BBDD}${NC}"
    echo -e "        3.2. Support email: ${CYAN}${EMAIL}${NC}"
    echo -e "        3.3. Developer contact information: ${CYAN}${EMAIL}${NC}"
    echo -e "        3.4. Leave the other fields with its default values."
    echo -e "        3.5. Press the ${CYAN}save and continue${NC} button."
    echo -e "        3.6. Press the ${CYAN}save and continue${NC} button."
    echo -e "        3.7. Press the ${CYAN}save and continue${NC} button."
    echo -e "        3.8. Press the ${CYAN}return to panel${NC} button."
    echo ""
    echo -e "    4. At the left panel, go to: ${CYAN}API and services -> Credentials${NC}"
    echo -e "        4.1. Press the ${CYAN}create credentials${NC} button."
    echo -e "        4.2. Select the ${CYAN}OAuth client ID${NC} option."
    echo -e "        4.3. Application type: ${CYAN}Web application${NC}"
    echo -e "        4.4. Name: ${CYAN}${BBDD}${NC}"
    echo -e "        4.5. Authorized JavaScript origins → Add URI: ${CYAN}${URL}${NC}"
    echo -e "        4.6. Authorized redirect URIs → Add URI: ${CYAN}${URL}/google/login/callback/${NC}"
    echo -e "        4.7. Press the ${CYAN}create${NC} button."
    echo -e "        4.8. Copy your ${CYAN}client id${NC} and ${CYAN}secret key${NC}, it will be required later."
    echo ""
    echo -e "Once completed the previous configuration, ${ORANGE}press any key to continue...${NC}"
    read 

    echo ""
    echo -e "${LCYAN}Setting up django's social account:${NC}"
    CURRENT=${PWD##*/}
    
    cd ${DIR}
    python3 manage.py runserver 0.0.0.0:8000  > /dev/null 2>&1 &  #use '0.0.0.0:8000' when running within a container, in order to allow remote connections
    PID=$!  

    echo -e "    1. Visit the django's admin site ${CYAN}${URL}/admin${NC} and log in as ${CYAN}${BBDD}${NC} superuser."
    echo -e "    2. Go to Sites → Site → Add site. Set it up:"
    echo -e "        Domain name: ${CYAN}${URL}${NC}"
    echo -e "        Display name: ${CYAN}${URL}${NC}"
    echo -e "    3. Go to Social accounts → Social applications → Add social application. Set it up:"
    echo -e "        Provider: ${CYAN}Google${NC}"
    echo -e "        Name: ${CYAN}google-api${NC}"
    echo -e "        Client id: ${CYAN}<your client id>${NC}"
    echo -e "        Secret key: ${CYAN}<your secret key>${NC}"
    echo -e "        You can leave the ${CYAN}key${NC} field empty."
    echo -e "    4. Add ${CYAN}${HOST}:8000${NC} to Chosen sites and save the new settings."
    echo ""
    echo -e "Once completed the previous configuration, ${ORANGE}press any key to continue...${NC}"
    read 

    kill $PID
    cd $HOME/${CURRENT}
    touch $MARK

  else
    echo -e "${CYAN}Google Authentication setup already done, skipping...${NC}"
  fi
}

setup_site(){
  MARK="$DIR/setup-site.done"
  FILE="$DIR/home/settings.py"

  echo ""  
  if ! [ -f "$MARK" ]; then    
    echo -e "${LCYAN}Setting up the site django data within ${CYAN}${FILE}${LCYAN}:${NC}"
    echo "Setting up the site secret key..." 
    SECRET=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    sed -i "s/'YOUR-SECRET-KEY'/'${SECRET}'/g" ${FILE}          

    ID=$(runuser -l postgres -c "psql -d \"${BBDD}\" -qtAX -c 'SELECT * FROM django_site WHERE name='\'${HOST}:8000\'';'")    
    if ! [ -z "$ID" ]; then    
      echo "Setting up the site ID..."    
      sed -i "s/'SITE_ID = 1'/'SITE_ID = ${ID}'/g" ${FILE}
    fi

    touch $MARK
  else
    echo -e "${CYAN}Django file ${LCYAN}${FILE}${CYAN} setup for the site data is already done, skipping...${NC}"
  fi
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

setup_gauth

trap : 0
echo ""
echo -e "${GREEN}Done!${NC}" 