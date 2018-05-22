#!/bin/bash

NAME='fgielow/energyplus'

[[ ! -f parallel ]] && wget http://git.savannah.gnu.org/cgit/parallel.git/plain/src/parallel && chmod 755 parallel

[[ -f tasks.txt ]] && rm tasks.txt

# JUST DO DOWNLOAD DOCKER
docker run --rm ${NAME} EnergyPlus --idd /usr/local/EnergyPlus-8-9-0/Energy+.idd -r -x -m 2> /dev/null || echo 0


n=$(ps aux | grep EnergyPlus | grep -c "docker run")

[[ $n -gt 0 ]] && echo "SIMULATIONS ALREADY IN PROGRESS PLEASE WAIT OR KILL THEN" || echo "SIMULATIO WILL NOW RUN IN BACKGROUND"