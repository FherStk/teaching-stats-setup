# teaching-stats-setup
Setup project for teaching-stats. 

## Requisites
This project has been tested only under Ubuntu 20.04 LTS.

## Under developement
The project is still under development and has not been completed yet. Please, refer to each release description for further information.

## How to install
1. Download the project with `git clone --recurse-submodules https://github.com/FherStk/teaching-stats-setup.git`
2. Go to the downloaded project with `cd teaching-stats-setup`
3. Install the app with `sudo ./install-localhost.sh` and follow the instructions.

## How to open/close the survey season
1. In order to open, run: `sudo ./config.sh survey open`
1. In order to close, run: `sudo ./config.sh survey close`

## How to add/remove users with access to the survey results
1. In order to add, run: `sudo ./config.sh staff add <email> <name> <surname>`
1. In order to remove, run: `sudo ./config.sh staff remove <email>`

## How to start the survey server
1. In order to start, run: `sudo ./start.sh`