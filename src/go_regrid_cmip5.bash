#!/bin/sh
#for model in GFDL-CM3 GFDL-ESM2m GISS-E2-H HadGEM2-CC HadGEM2-ES
#for model in CESM1-CAM5

#for model in ACCESS1-3 CanESM2 CCSM4 GFDL-CM3 GFDL-ESM2M GISS-E2-H HadGEM2-CC HadGEM2-ES CMCC-CM CNRM-CM5 CSIRO-Mk3-6-0 IPSL-CM5A-MR inmcm4 MIROC5 MIROC-ESM MPI-ESM-LR MPI-ESM-MR MRI-CGCM3 NorESM1-M
for model in CanESM2
do

#  for exp in historical
  for exp in rcp85
  do

#    for var in zg ta ua va hus hur ts
#    for var in zg
    for var in hur
    do
      echo '"'${model}'"' '"'${exp}'"' '"'${var}'"'

      ncl 'ModelName="'${model}'"' 'InDir="/glade/p/ualb0006/chenl/CMIP5/'${model}'/ORIGIN/"' 'LatName="lat"' 'LonName="lon"' 'LatCornerName="lat_bnds"' 'LonCornerName="lon_bnds"' 'FileType="nc"' 'frequency="Amon"' 'Experiment="'${exp}'"' 'Var="'${var}'"'  ESMF_rec_to_1deg_3D.ncl

    done
  done
done
