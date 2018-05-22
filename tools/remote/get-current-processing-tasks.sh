#!/bin/bash

ps aux | grep EnergyPlus | grep "docker run" | grep -oE "input-files.*simdata" | cut -d"/" -f2