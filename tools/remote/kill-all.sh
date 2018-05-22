#!/bin/bash

ps aux | grep EnergyPlus | awk '{print $2}' | xargs kill -9

ps aux | grep parallel-process.sh | awk '{print $2}' | xargs kill -9