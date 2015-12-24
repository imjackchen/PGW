#!/bin/bash

#exp=historical
exp=rcp85

for month in 01 02 03 04 05 06 07 08 09 10 11 12
do
  echo "Working on month: " ${month}

  ncra *_${exp}_ens_mean_${month}.nc -o ${exp}_${month}_mean.nc

done

#annual
ncra *_${exp}_ens_mean_annual.nc -o ${exp}_annual_mean.nc
