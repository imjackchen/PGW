#!/bin/sh

exp=${1}   #needs to be historical or rcp85
model=${2} #model name: e.g. cesm1-cam5  -> match directories in experiemnt directory
ens=${3}   #ensemble number

#cd ./${exp}/${model}/${ens}

for mnth in 01 02 03 04 05 06 07 08 09 10 11 12
do

  echo "Averaging: "${model}", "${exp}", "${ens}", "${mnth}

  ncra met_em.d01.????-${mnth}-??_??:??:??.nc -o ${model}_${exp}_${mnth}_avg.nc

done

ncra ${model}_${exp}_??_avg.nc -o ${model}_${exp}_annual_avg.nc
