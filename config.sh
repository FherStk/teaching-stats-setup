#!/bin/bash
YELLOW='\033[1;33m'
RED='\033[0;31m'

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
    echo
}

trap 'abort' 0
set -e

FILE="/var/www/teaching-stats/social_app/urls.py"
MODE=${1}
OPTION=${2}

bash ./info.sh "Config"

if [ "$MODE"="survey" ]; then    
    if [ "$OPTION"="open" ]; then    
        sed -i "s/#path('', TemplateView.as_view(template_name=\"social_app/index.html\"), name='homepage'),/path('', TemplateView.as_view(template_name=\"social_app/index.html\"), name='homepage')/g" ${FILE}
        sed -i "s/path('', TemplateView.as_view(template_name=\"social_app/survey_closed.html\"), name='homepage'),/#path('', TemplateView.as_view(template_name=\"social_app/survey_closed.html\"), name='homepage')/g" ${FILE}
        
        echo "Survey seasson is currently open."
    elif [ "$OPTION"="close" ]; then    
        sed -i "s/path('', TemplateView.as_view(template_name=\"social_app/index.html\"), name='homepage'),/#path('', TemplateView.as_view(template_name=\"social_app/index.html\"), name='homepage')/g" ${FILE}
        sed -i "s/#path('', TemplateView.as_view(template_name=\"social_app/survey_closed.html\"), name='homepage'),/path('', TemplateView.as_view(template_name=\"social_app/survey_closed.html\"), name='homepage')/g" ${FILE}
        
        echo "Survey seasson is currently closed."
    else
        options
    fi

else
    options
fi


trap : 0
echo ""