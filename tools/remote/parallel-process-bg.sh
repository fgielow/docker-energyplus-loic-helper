#!/bin/bash

NAME='fgielow/energyplus'

n=$(ps aux | grep EnergyPlus | grep -c "docker run")

[[ $n -gt 0 ]] && exit 1

for f in $(ls -d input-files/*/)
do
  echo "docker run --rm -v `pwd`/${f}:/var/simdata ${NAME} EnergyPlus --idd /usr/local/EnergyPlus-8-9-0/Energy+.idd -r -x -m"
  cp /root/in.epw `pwd`/${f}/in.epw
done > tasks.txt

echo "cat /root/tasks.txt | /root/parallel -j 4" > parallel-process-tasks.sh

chmod +x parallel-process-tasks.sh

/root/parallel-process-tasks.sh