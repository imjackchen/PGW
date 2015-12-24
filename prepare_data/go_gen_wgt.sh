#!/bin/sh

ncl 'ModelName="CanESM2"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_CanESM2_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="CCSM4"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_CCSM4_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="ACCESS1-3"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_ACCESS1-3_amip_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="CESM1-CAM5"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_CESM1-CAM5_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="CMCC-CM"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_CMCC-CM_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="CNRM-CM5"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_CNRM-CM5_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="CSIRO-Mk3-6-0"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_CSIRO-Mk3-6-0_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="GFDL-CM3"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_GFDL-CM3_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="GFDL-ESM2M"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_GFDL-ESM2M_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="GISS-E2-H"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_GISS-E2-H_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="HadGEM2-CC"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_HadGEM2-CC_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="HadGEM2-ES"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_HadGEM2-ES_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="inmcm4"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_inmcm4_amip_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="IPSL-CM5A-MR"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_IPSL-CM5A-MR_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="MIROC5"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_MIROC5_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="MIROC-ESM"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_MIROC-ESM_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="MPI-ESM-LR"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_MPI-ESM-LR_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="MPI-ESM-MR"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_MPI-ESM-MR_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="MRI-CGCM3"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_MRI-CGCM3_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl

ncl 'ModelName="NorESM1-M"' 'srcFileName="/glade/scratch/chenl/CMIP5/static_file/orog_fx_NorESM1-M_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=9000' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl
