#!/bin/bash

eval `echo kill -9 $(ps aux | grep parallel-process | awk '{print $2}')`

sleep 1

eval `echo kill -9 $(ps aux | grep EnergyPlus | awk '{print $2}')`