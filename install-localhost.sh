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
LOCALHOST="127.0.0.1" #Used for local connections like Django -> postgres
PSQL_PORT="5432"
PASS=''
EMAIL=''
HOST='' #used to allow remote to local connections, useful when running within containers
LXD=''


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
    if [ -f "$MARK" ]; then 
      echo -e "${LCYAN}Installing requirements: ${CYAN}${1} v${2}${NC}"
      pip3 install ${1}==${2};    
    else
      echo -e "${LCYAN}Installing requirements: ${CYAN}${1}${NC}"
      pip3 install ${1};      
    fi
    
  else 
    echo -e "${CYAN}Requirement ${LCYAN}${1}${CYAN} already satisfied, skipping...${NC}"
  fi
}

lxd_req()
{
  if [ -z "$LXD" ]; then   
    echo 
    echo -e "${ORANGE}Is this instance running within an ${CYAN}LXD${ORANGE} container or similar?${NC} [y/N]"
    read LXD

    if [ "$LXD"="y" ]; then    
      LXD="TRUE"
    else
      LXD="FALSE"
    fi
  fi
}

pwd_req()
{  
  if [ -z "$PASS" ]; then
    FILE="$DIR/setup-files.pass"

    if ! [ -f "$FILE" ]; then    
      while true; do        
        echo
        echo -e "${ORANGE}Please, provide the password for all the applications involded into the ${CYAN}${BBDD}${ORANGE} setup:${NC}"
        read -s PASS

        echo -e "${ORANGE}Set the password (again):${NC}"
        read -s PASS2
        echo ""

        [ "$PASS" = "$PASS2" ] && break
        echo -e "${RED}Password missmatch, please try again.${NC}"
        echo ""
      done  

      touch $FILE
      echo $PASS > $FILE
    else
      PASS=$(cat ${FILE})
    fi    
  fi
}

host_req()
{
  if [ -z "$HOST" ]; then    
    FILE="$DIR/setup-files.host"

    if ! [ -f "$FILE" ]; then   
      lxd_req    

      IPv4=$(hostname -I | cut -d' ' -f1)
      if [ "$LXD"="TRUE" ]; then    
        HOST=${IPv4}
      else
        HOST=${LOCALHOST}
      fi

      touch $FILE
      echo $HOST > $FILE

    else
      HOST=$(cat ${FILE})
    fi   
  fi
}

email_req()
{
  if [ -z "$EMAIL" ]; then    
    FILE="$DIR/setup-files.mail"

    if ! [ -f "$FILE" ]; then    
      echo
      echo -e "${ORANGE}Please, provide the email for all the applications involded into the ${CYAN}${BBDD}${ORANGE} setup:${NC}"
      echo -e "${RED}Warning! This email will be attached to the Django superuser and won't be able to join (or review the results of) any survey.${NC}"
      read EMAIL  
      
      touch $FILE
      echo $EMAIL > $FILE
    else
      EMAIL=$(cat ${FILE})
    fi  
  fi 
}

collect_data()
{  
  MARK="$DIR/collect-data.done"

  echo ""
  if ! [ -f "$MARK" ]; then    
    echo -e "${LCYAN}Collecting data for the ${CYAN}${BBDD}${LCYAN} ecosystem setup:${NC}"
    echo -e "The ${LCYAN}${BBDD}${NC} setup relays on a bunch of applications that works together to provide a set of survey capabilities, in order to simplify the installation and configuration process, the same users, passwords and emails will be used along all the setup process."    

    echo
    echo -e "The ${LCYAN}${BBDD}${NC} username will be used for all the applications involded into the ${LCYAN}${BBDD}${NC} setup."    
    email_req
    pwd_req    
    host_req

    touch $MARK
  else
    echo -e "${CYAN}Setup ${LCYAN}${BBDD}${CYAN} data already collected, skipping...${NC}"
    
    #data will be loaded from the existing files, no promt nor output required    
    email_req
    pwd_req    
    host_req
  fi
}

clean_data()
{  
  MARK="$DIR/collect-data.done"
  HOSTFILE="$DIR/setup-files.host"
  MAILFILE="$DIR/setup-files.mail"
  PWDFILE="$DIR/setup-files.pass"

  echo ""
  if ! [ -f "$MARK" ]; then    
    echo -e "${CYAN}No setup ${LCYAN}${BBDD}${CYAN} data has been collected, skipping...${NC}"
  else    
    echo -e "${LCYAN}Cleaning collected data for the ${CYAN}${BBDD}${LCYAN} ecosystem setup:${NC}"
    
    echo -e "Cleaning host..."
    rm ${HOSTFILE}

    echo -e "Cleaning email..."
    rm ${MAILFILE}

    echo -e "Cleaning credentials..."
    rm ${PWDFILE}
  fi
}

bbdd_create()
{
  echo ""
  if [ $(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -c $1") -eq 0 ];
  then    
    echo -e "${LCYAN}Creating the ${CYAN}$1${LCYAN} database:${NC}"
    runuser -l postgres -c "createdb -e $1"
  else
    echo -e "${CYAN}The database ${LCYAN}$1${CYAN} already exists, skipping...${NC}"
  fi
}

bbdd_user()
{
  echo ""
  if [ $(runuser -l postgres -c "psql -c \"\\du ${BBDD}\" | cut -d \| -f 1 | grep -c ${BBDD}") -eq 0 ];
  then          
    echo -e "${LCYAN}Creating the ${CYAN}${BBDD}${LCYAN} database user:${NC}"
    echo -e "A PostgreSQL user named ${CYAN}${BBDD}${NC} will be created into the ${CYAN}${BBDD}${NC} database, which will be its owner with all granted permissions."
    echo

    runuser -l postgres -c "psql -e -c 'CREATE USER \"${BBDD}\" WITH PASSWORD '\'${PASS}\'';'"
    runuser -l postgres -c "psql -e -c 'ALTER DATABASE \"${BBDD}\" OWNER TO \"${BBDD}\";'"

  else
    echo -e "${CYAN}The database user ${LCYAN}${BBDD}${CYAN} already exists, skipping...${NC}"
  fi
}

bbdd_schema()
{
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
    echo -e "${LCYAN}Setting up the initial Django data within ${CYAN}${FILE}${LCYAN}:${NC}"
    echo "Setting up database name..."
    sed -i "s/'YOUR-DATABASE'/'${BBDD}'/g" ${FILE}

    echo "Setting up database user..."
    sed -i "s/'YOUR-USER'/'${BBDD}'/g" ${FILE}

    echo "Setting up database host..."
    sed -i "s/'YOUR-HOST'/'localhost'/g" ${FILE}

    echo "Setting up database port..."
    sed -i "s/'YOUR-PORT'/'${PSQL_PORT}'/g" ${FILE}    
    
    echo "Setting up database password..."
    sed -i "s/'YOUR-PASSWORD'/'${PASS}'/g" ${FILE}
        
    echo "Setting up the allowed hosts..."     
    sed -i "s/ALLOWED_HOSTS = \['localhost'\]/ALLOWED_HOSTS = \['${HOST}','${BBDD}.com'\]/g" /var/www/teaching-stats/home/settings.py      

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
    echo -e "${LCYAN}Setting up the ${CYAN}${BBDD}${LCYAN} Django instance:${NC}"
    
    CURRENT=${PWD}
    
    cd ${DIR}
    python3 manage.py makemigrations --noinput
    
    echo ""  
    python3 manage.py migrate --noinput  
    python3 dbsetup.py
    python3 manage.py collectstatic --noinput
    
    echo ""    
    echo -e "${LCYAN}Setting up the ${CYAN}${BBDD}${LCYAN} Django superuser:${NC}"
    echo -e "A Django superuser named ${CYAN}${BBDD}${NC} will be created into the ${CYAN}${BBDD}${NC} Django instance, use this user to login into Django as an administrator."    
    echo ""

    DJANGO_SUPERUSER_PASSWORD=${PASS} \
    python3 manage.py createsuperuser --noinput --username ${BBDD} --email ${EMAIL}

    cd ${CURRENT}
    touch $MARK
  else
    echo -e "${CYAN}Django instance ${LCYAN}${FILE}${CYAN} setup already done, skipping...${NC}"
  fi
}

setup_gauth()
{
  MARK="$DIR/setup-gauth.done"
  
  echo ""  
  if ! [ -f "$MARK" ]; then             
    URL="http://${HOST}:8000"

    echo -e "${LCYAN}Setting up Google Authentication:${NC}"
    echo ""

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

    if [ "$HOST"=="127.0.0.1" ]; then
      echo -e "        4.5. Authorized JavaScript origins → Add URI: ${CYAN}http://${HOST}:8000${NC}"                    
      echo -e "        4.6. Authorized redirect URIs → Add URI: ${CYAN}http://${HOST}:8000/google/login/callback/${NC}" 
    else
      echo -e "        4.5. Authorized JavaScript origins → Add URI: ${CYAN}http://${BBDD}.com:8000${NC}"                   
      echo -e "        4.6. Authorized redirect URIs → Add URI: ${CYAN}http://${BBDD}.com:8000/google/login/callback/${NC}"        
    fi

    echo -e "        4.7. Press the ${CYAN}create${NC} button."
    echo -e "        4.8. Copy your ${CYAN}client id${NC} and ${CYAN}secret key${NC}, it will be required later."

    if [ "$HOST"=="127.0.0.1" ]; then                 
      echo
      echo -e "    5. In order to login using your Google credentials, edit your local ${CYAN}/etc/hosts${NC} file, otherwise, your browser won't be able to login."
      echo -e "        5.1 Edit your local hosts file with ${CYAN}sudo nano /etc/hosts${NC} or the text editor you wish."
      echo -e "        5.2 Add the follogin entry at the begining: ${CYAN}${HOST} ${BBDD}.com${NC}."
      echo -e "        5.3 Save the changes."          
    fi
    
    echo ""
    echo -e "${ORANGE}Once completed the previous configuration, press any key to continue...${NC}"
    read 

    if [ "$HOST"=="127.0.0.1" ]; then                 
      #service network-manager restart 
      systemctl restart systemd-hostnamed
    fi

    echo ""
    echo -e "${LCYAN}Setting up Django's social account:${NC}"
    CURRENT=${PWD}
        
    cd ${DIR}
    python3 manage.py runserver 0.0.0.0:8000  > /dev/null 2>&1 &  #use '0.0.0.0:8000' when running within a container, in order to allow remote connections
    PID=$!  

    echo -e "    1. Visit the Django's admin site ${CYAN}${URL}/admin${NC} and log in as ${CYAN}${BBDD}${NC} superuser."
    echo -e "    2. Go to Sites → Site → Add site. Set it up:"
    echo -e "        Domain name: ${CYAN}${BBDD}.com:8000${NC}"
    echo -e "        Display name: ${CYAN}${BBDD}${NC}"
    echo -e "    3. Go to Social accounts → Social applications → Add social application. Set it up:"
    echo -e "        Provider: ${CYAN}Google${NC}"
    echo -e "        Name: ${CYAN}google-api${NC}"
    echo -e "        Client id: ${CYAN}<your client id>${NC}"
    echo -e "        Secret key: ${CYAN}<your secret key>${NC}"
    echo -e "        You can leave the ${CYAN}key${NC} field empty."
    echo -e "    4. Add ${CYAN}${BBDD}.com:8000${NC} and ${CYAN}example.com${NC} to Chosen sites and save the new settings."
    echo ""
    echo -e "${ORANGE}Once completed the previous configuration, press any key to continue...${NC}"
    read 

    kill $PID
    cd ${CURRENT}
    touch $MARK

  else
    echo -e "${CYAN}Google Authentication setup already done, skipping...${NC}"
  fi
}

setup_site()
{
  MARK="$DIR/setup-site.done"
  FILE="$DIR/home/settings.py"

  echo ""  
  if ! [ -f "$MARK" ]; then    
    echo -e "${LCYAN}Setting up the site Django data within ${CYAN}${FILE}${LCYAN}:${NC}"
    echo "Setting up the site secret key..." 
    SECRET=$(python -c 'from Django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
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

populate()
{
  MARK="$DIR/populate-$1.done"
  FOLDER="$2"
  FILE=${FOLDER}/database.ini

  echo ""  
  if ! [ -f "$MARK" ]; then        
    echo -e "${LCYAN}Populating $1 data within the ${CYAN}${BBDD}${LCYAN} database:${NC}"    
    echo -e "    1. Go to the ${CYAN}${FOLDER}${NC} folder."
    echo -e "    2. Review each $1 file and perform any modification you need."
    echo -e "    3. Each $1 file will be loaded and its data will be pupulated through the database."
    echo ""
    echo -e "${ORANGE}Once completed the previous configuration, press any key to continue...${NC}"
    read CONTINUE    

    echo ""  
    echo -e "${LCYAN}Setting up the ${CYAN}${FILE}${LCYAN} connection file:${NC}"    
    touch ${FILE}
    echo "[postgresql]" >> ${FILE}
    echo "host=${LOCALHOST}" >> ${FILE}
    echo "database=${BBDD}" >> ${FILE}
    echo "user=${BBDD}" >> ${FILE}
    echo "password=${PASS}" >> ${FILE}
    echo "port=${PSQL_PORT}" >> ${FILE}
    echo "options=-c search_path=dbo,master" >> ${FILE}
    echo "File successfully created."

    echo ""  
    echo -e "${LCYAN}Starting the ${CYAN}${BBDD}${LCYAN} database population for $1 data:${NC}"    
    cd ${FOLDER}      
    python3 $3
    cd ..

    touch $MARK
  else
    echo -e "${CYAN}The ${LCYAN}$1${CYAN} data for the ${LCYAN}${BBDD}${CYAN} database already populated, skipping...${NC}"
  fi
}

metabase_env()
{
  MARK="$DIR/metabase-env.done"
  USER="metabase"
  FOLDER="/opt/${USER}"

  echo ""  
  if ! [ -f "$MARK" ]; then          
    echo -e "${CYAN}Setting up the ${LCYAN}${USER}${CYAN} environment:${NC}"

    if [ $(getent group ${USER}) ]; then
      echo -e "   Group ${LCYAN}${USER}${NC} already exists, skipping..."
    else
      echo -e "   Creating the ${LCYAN}${USER}${NC} group..."
      sudo addgroup --quiet --system ${USER}
    fi

    if id "$USER" &>/dev/null; then
      echo -e "   User ${LCYAN}${USER}${NC} already exists, skipping..."
    else
      echo -e "   Creating the ${LCYAN}${USER}${NC} user..."
      sudo adduser --quiet --system --ingroup ${USER} --no-create-home --disabled-password ${USER}
    fi

    echo -e "   Creating the ${LCYAN}${USER}${NC} directory..."
    mkdir -p ${FOLDER}
    sudo chown -R ${USER}:${USER} ${FOLDER}

    FILE_ENV="/etc/default/${USER}"
    echo -e "   Setting up the ${LCYAN}${USER}${NC} enviroment..."
    touch ${FILE_ENV}
    sudo chmod 640 ${FILE_ENV}

    FILE_LOG="/var/log/${USER}.log"
    echo -e "   Setting up the ${LCYAN}${USER}${NC} log files..."
    touch ${FILE_LOG}
    sudo chown ${USER}:${USER} ${FILE_LOG}

    FILE_CON="/etc/rsyslog.d/${USER}.conf"
    echo -e "   Setting up the ${LCYAN}${USER}${NC} config files..."
    touch ${FILE_CON}
    echo ":msg,contains,\"metabase\" ${FILE_LOG} & stop" >> ${FILE_CON}

    FILE_CON="/etc/rsyslog.conf"
    
    lxd_req        
    if [ "$LXD"="TRUE" ]; then    
      sed -i "s/module(load=\"imklog\"/#module(load=\"imklog\"/g" ${FILE_CON}
    else
      sed -i "s/#module(load=\"imklog\"/module(load=\"imklog\"/g" ${FILE_CON}
    fi

    echo -e "   Restarting the ${LCYAN}rsyslog${NC} service..."
    systemctl restart rsyslog

    touch $MARK
  else
    echo -e "${CYAN}The ${LCYAN}${USER}${CYAN} environment is already setup, skipping...${NC}"
  fi
}

metabase_download()
{
  MARK="$DIR/metabase-download.done"  

  echo ""  
  if ! [ -f "$MARK" ]; then      
    echo -e "${CYAN}Downloading the lastest ${LCYAN}${USER}${CYAN} app version:${NC}"
    wget https://downloads.metabase.com/v0.42.2/metabase.jar -O /opt/metabase/metabase.jar

    touch $MARK
  else
    echo -e "${CYAN}The ${LCYAN}${USER}${CYAN} app is already downloaded, skipping...${NC}"
  fi
}

metabase_bbdd()
{
  MARK="$DIR/metabase-bbdd.done"    
  METABASE="${BBDD}-metabase"

  if ! [ -f "$MARK" ]; then          
    bbdd_create "${BBDD}-metabase"          
    runuser -l postgres -c "psql -e -c 'ALTER DATABASE \"${METABASE}\" OWNER TO \"${BBDD}\";'"
    runuser -l postgres -c "psql -d \"${METABASE}\" -e -c 'ALTER SCHEMA \"public\" OWNER TO \"${BBDD}\";'"
    runuser -l postgres -c "psql -d \"${METABASE}\" -e -c 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;'"    

    touch $MARK
  else
    echo 
    echo -e "${CYAN}The ${LCYAN}${USER}${CYAN} database already exists, skipping...${NC}"
  fi
}

metabase_service()
{
  MARK="$DIR/metabase-service.done"
  USER="metabase"
  SERVICE="/etc/systemd/system/metabase.service"
  FILE="/opt/metabase/metabase-postgres.sh"

  echo ""  
  if ! [ -f "$MARK" ]; then      
    echo -e "${CYAN}Setting up the ${LCYAN}${USER}${CYAN} service:${NC}"    
    echo -e "   Creating the execution script for the current ${LCYAN}${USER}${NC} instance..."
    touch $FILE

    echo "#!/bin/bash" >> ${FILE}
    echo "cd /opt/metabase" >> ${FILE}
    echo "export MB_DB_TYPE=postgres" >> ${FILE}
    echo "export MB_DB_DBNAME=${BBDD}-metabase" >> ${FILE}
    echo "export MB_DB_PORT=5432" >> ${FILE}
    echo "export MB_DB_USER=${BBDD}" >> ${FILE}
    echo "export MB_DB_PASS=${PASS}" >> ${FILE}
    echo "export MB_DB_HOST=127.0.0.1" >> ${FILE}
    echo "/usr/bin/java -jar metabase.jar" >> ${FILE}
    
    chmod +x $FILE

    echo -e "   Creating the service file for the current ${LCYAN}${USER}${NC} instance..."
    touch $SERVICE
    echo "[Unit]" >> ${SERVICE}
    echo "Description=Metabase Server" >> ${SERVICE}
    echo "After=syslog.target" >> ${SERVICE}
    echo "After=network.target" >> ${SERVICE}
    echo "" >> ${SERVICE}
    echo "[Service]" >> ${SERVICE}
    echo "WorkingDirectory=/opt/metabase" >> ${SERVICE}
    echo "ExecStart=/usr/bin/bash ${FILE}" >> ${SERVICE}
    echo "EnvironmentFile=/etc/default/metabase" >> ${SERVICE}
    echo "User=metabase" >> ${SERVICE}
    echo "Type=simple" >> ${SERVICE}
    echo "StandardOutput=syslog" >> ${SERVICE}
    echo "StandardError=syslog" >> ${SERVICE}
    echo "SyslogIdentifier=metabase" >> ${SERVICE}
    echo "SuccessExitStatus=143" >> ${SERVICE}
    echo "TimeoutStopSec=120" >> ${SERVICE}
    echo "Restart=always" >> ${SERVICE}
    echo "" >> ${SERVICE}
    echo "[Install]" >> ${SERVICE} 
    echo "WantedBy=multi-user.target" >> ${SERVICE}

    echo -e "   Reloading the systemd daemon..."
    sudo systemctl daemon-reload 

    echo -e "   Starting the ${LCYAN}${USER}${NC} service..."
    sudo systemctl enable metabase.service   
    touch $MARK
  else
    echo -e "${CYAN}The ${LCYAN}${USER}${CYAN} service already exists, skipping...${NC}"
  fi
}

metabase_master()
{
  MARK="$DIR/metabase-master.done"
  FOLDER=/tmp/teaching-stats
  DUMP=$FOLDER/metabase.sql
  USER="metabase"  

  echo ""  
  if ! [ -f "$MARK" ]; then      
    echo -e "${CYAN}Setting up the ${LCYAN}${USER}${CYAN} database:${NC}"     

    mkdir -p $FOLDER
    cp -f resources/metabase.sql $DUMP        

    sed -i "s/###PSQLPWD###/${PASS}/g" ${DUMP}
    sed -i "s/admin@admin.com/${EMAIL}/g" ${DUMP}

    runuser -l postgres -c "psql -v ON_ERROR_STOP=1 -d \"${METABASE}\" -e < ${DUMP}"    

    touch $MARK
  else
    echo -e "${CYAN}The metabase ${LCYAN}${USER}${CYAN} database has been already setup, skipping...${NC}"
  fi
}

metabase_setup()
{
  MARK="$DIR/metabase-setup.done"
  FILE="/opt/metabase/metabase-postgres.sh"
  FOLDER=/tmp/teaching-stats
  USER="metabase"
  
  echo ""  
  if ! [ -f "$MARK" ]; then      
    echo -e "${CYAN}Setting up the ${LCYAN}${USER}${CYAN} instance:${NC}"         
    echo "   Preparing the reset token for the admin password, it can take a while..."
    sed -i "s/-jar metabase.jar/-jar metabase.jar reset-password ${EMAIL}/g" ${FILE}
    RESULT=$(bash ${FILE})
    TOKEN=$(echo ${RESULT} | grep -oP '(?<=\[\[\[).+?(?=\]\]\])')    
    
    echo "   Starting metabase, please wait..."
    sed -i "s/-jar metabase.jar reset-password ${EMAIL}/-jar metabase.jar/g" ${FILE}
    sudo systemctl start metabase.service
    sleep 10  #TODO: should wait till metabase is ready

    echo
    echo -e "   The ${CYAN}metabase${NC} admin's password cannot be setup automatically, so even than any password can be provided, its recommended to use the same as provided before:"
    echo -e "    1. Visit the current instance of Metabase at ${CYAN}http://${HOST}:3000/auth/reset_password/${TOKEN}${NC}"
    echo -e "    2. Set your new ${CYAN}metabase admin password${NC}."    
    echo 
    echo -e "${ORANGE}Once completed the previous configuration, press any key to continue...${NC}"
    read CONTINUE    

    sudo systemctl stop metabase.service
    touch $MARK
  else
    echo -e "${CYAN}The metabase ${LCYAN}${USER}${CYAN} instance is already setup, skipping...${NC}"
  fi
}

metabase_dashboards()
{
  MARK="$DIR/metabase-dashboards.done"
  FOLDER="/var/www/teaching-stats/templates/analytics"
  URL="http://${HOST}:3000/public/dashboard"
  USER="metabase"  

  echo ""  
  if ! [ -f "$MARK" ]; then      
    echo -e "${CYAN}Setting up the ${LCYAN}${USER}${CYAN} dashboards:${NC}"  

    echo "   School analytics..."
    sed -i "s|YOUR-DASHBOARD-SHARED-URL|${URL}/347ad7db-6067-4471-aff9-c9dcfb0f9140|g" ${FOLDER}/school_analytics.html
    
    echo "   Administration analytics..."
    sed -i "s|YOUR-DASHBOARD-SHARED-URL|${URL}/db3ef531-8f78-4d92-91e6-f2055f38acb9|g" ${FOLDER}/adm_analytics.html
  
    echo "   Computer science analytics..."
    sed -i "s|YOUR-DASHBOARD-SHARED-URL|${URL}/d83e1ccb-bc1a-4c70-8695-f1619f0b8434|g" ${FOLDER}/inf_analytics.html

    echo "   Subject analytics..."
    sed -i "s|YOUR-DASHBOARD-SHARED-URL|${URL}/4cd9feed-60ca-4e43-8456-16ba64b2157c|g" ${FOLDER}/subject_analytics.html

    echo "   Counseling analytics..."
    sed -i "s|YOUR-DASHBOARD-SHARED-URL|${URL}/e8f9c352-0aca-4508-a766-d866e7de133a|g" ${FOLDER}/counseling_analytics.html
    
    touch $MARK
  else
    echo -e "${CYAN}The metabase ${LCYAN}${USER}${CYAN} dashboards has been already setup, skipping...${NC}"
  fi

  #Always starts metabase
  sudo systemctl start metabase.service
}


trap 'abort' 0
set -e

bash ./info.sh "Setup for localhost"

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
apt_req default-jre

pip_req django 4.0.1
pip_req django-allauth 0.47.0
pip_req psycopg2-binary 2.9.3
pip_req pytz

copy_files
collect_data

bbdd_create $BBDD
bbdd_user

bbdd_schema public
bbdd_schema master
bbdd_schema reports

setup_files
setup_django
setup_gauth

populate master teaching-stats-db-population insert_data.py
populate students teaching-stats-import-students insert_students.py

metabase_env
metabase_download
metabase_bbdd
metabase_service
metabase_master #TODO: metabase_master loads the master data but no data about answers.
metabase_setup
metabase_dashboards

clean_data

trap : 0
echo ""
echo -e "${GREEN}Done! Use the start script to run the app.${NC}" 