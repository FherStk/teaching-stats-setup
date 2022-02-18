#!/bin/sh
requirement()
{
  if [ $(dpkg-query -W -f='${Status}' $0 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    echo "Installing requirements: $0"
    apt-get install $0;
  fi
}

echo ""
echo "Setup for Teaching Stats: Install (v1.0.0)"
echo "Copyright © 2022: Marcos Alcocer Gil"
echo "Copyright © 2022: Fernando Porrino Serrano"
echo "Under the AGPL license: https://github.com/FherStk/teaching-stats-setup/blob/main/LICENSE"
echo ""
echo ""
echo "Updating repo list"
apt update

echo ""
requirement apache2

echo ""
requirement python3