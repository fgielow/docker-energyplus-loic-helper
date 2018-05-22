#!/bin/bash

n=$(ps aux | grep EnergyPlus | grep -c "docker run")

[[ $n -gt 0 ]] && echo "RESULTS NOT READY; STILL PROCESSING" || echo "NOTHING BEING PROCESSED NOW; IF THERE WERE REQUESTS THEY ARE PROBABLY FINISHED"