#!/bin/sh

ncl 'ModelName="CMCC-CM"' 'srcFileName="/glade/p/ualb0006/chenl/CMIP5/static_file/orog_fx_CMCC-CM_historical_r0i0p0.nc"' 'LatName="lat"' 'LonName="lon"' 'varname="orog"' 'varName="orog"' 'FileType="nc"' 'cnMin=0' 'cnMax=3500' 'cnSpace=250' ESMF_genWgts_rec_to_1deg.ncl
