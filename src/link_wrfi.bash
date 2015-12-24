#!/bin/bash


#command line arguments
#wdir:  base path to ensemble member WPS files
#ens:  which ensemble member to link

wdir=$1
ens=$2


#for exp in 20THC RCP85

for exp in 20THC
do
  \rm ./MODEL_${exp}*

  if [ ${exp} == "20THC" ]; then

    for yr in ${wdir}/${ens}/19?? ${wdir}/${ens}/200?
    do

      echo "linking: " ${yr}

      for file in ${yr}/*
      do

        pos=`expr index "${file}" :`
        date="${file:${pos}:13}"

        ln -sf ${file} MODEL_${exp}:${date}
        
      done

    done

  fi


  if [ ${exp} == "RCP85" ]; then

    for yr in ${wdir}/${ens}/20[789]? ${wdir}/${ens}/2100
    do

      echo "linking: " ${yr}

      for file in ${yr}/*
      do

        pos=`expr index "${file}" :`
        date="${file:${pos}:13}"

        ln -sf ${file} MODEL_${exp}:${date}

      done

    done

  fi


done
