#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BBDD='teaching-stats'

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
    echo "   survey restart: clears the participation data, so every user will be able to answer again."
    echo "   survey reset: clears the students, trainers and subject assignation data."
    echo "   staff add <email> <name> <surname>: adds a new staff member, so he/she will be able to access to the survey results."
    echo "   staff remove <email>: removes a staff member, so he/she will not be able to access to the survey results."
    echo
}

restart()
{
    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'TRUNCATE TABLE public.forms_participation;'"
    runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'SELECT pg_catalog.setval('\'public.forms_participation_id_seq\'', 1, true);'"                                    
}

trap 'abort' 0
set -e

FILE="/var/www/teaching-stats/social_app/urls.py"
MODE=${1}
OPTION=${2}

bash ./info.sh "Config"

if [ "$MODE" == "survey" ]; then
    if [ "$OPTION" == "open" ]; then    
        cp -f resources/urls-open.py ${FILE}   
        echo     
        echo -e "${GREEN}Survey seasson is currently open.${NC}"

    elif [ "$OPTION" == "close" ]; then    
        cp -f resources/urls-closed.py ${FILE}
        echo   
        echo -e "${RED}Survey seasson is currently closed.${NC}"

    elif [ "$OPTION" == "restart" ]; then    
        echo -e "${RED}Warning! Cleaning the participation allows the participants to answer again to the current survey, incurring into possible duplications.${NC}"
        echo -e "Do you want to proceed? [n/Y]"

        read CONFIRM
        if [ "$CONFIRM" == "Y" ]; then
            restart
            echo   
            echo -e "${GREEN}Participation data has been erased.${NC}"
        else
            echo -e "Skipping..."
        fi   

    elif [ "$OPTION" == "reset" ]; then    
        echo -e "${RED}Warning! The list of trainers, students and the subjects assigned to each of them will be erased, including the participation data. No participant will be able to joint the survey till this data became reintroduced into the system.${NC}"
        echo -e "Do you want to proceed? [n/Y]"

        read CONFIRM
        if [ "$CONFIRM" == "Y" ]; then
            restart
            
            runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'TRUNCATE TABLE public.subject_student;'"
            runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'TRUNCATE TABLE public.student;'"
            runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'TRUNCATE TABLE public.subject_trainer_group;'"
            
            runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'SELECT pg_catalog.setval('\'public.student_id_seq\'', 1, true);'" 
            runuser -l postgres -c "psql -d \"${BBDD}\" -e -c 'SELECT pg_catalog.setval('\'public.subject_trainer_group_id_seq\'', 1, true);'"                                    

            echo   
            echo -e "${GREEN}The list of trainers and students has been erased.${NC}"
        else
            echo -e "Skipping..."
        fi 
    else
        options
    fi

elif [ "$MODE" == "staff" ]; then
    EMAIL=${3}
    BBDD='teaching-stats'
    
    if [ "$OPTION" == "add" ]; then        
        NAME=${4}
        SURNAME=${5}    
        
        runuser -l postgres -c "psql -d \"${BBDD}\" -c 'INSERT INTO reports.staff (email, name, surname, position) VALUES('\'${EMAIL}\'', '\'${NAME}\'', '\'${SURNAME}\'', (SELECT COUNT(id)+1 FROM reports.staff));'"
        echo -e "${GREEN}Done!${NC}" 
    elif [ "$OPTION" == "remove" ]; then
        runuser -l postgres -c "psql -d \"${BBDD}\" -c 'DELETE FROM reports.staff WHERE email='\'${EMAIL}\'';'"
        echo -e "${GREEN}Done!${NC}" 
    else
        options
    fi
else
    options
fi

trap : 0
echo ""