#!/bin/bash

# --------------------------------------------------------------------------------
# Aim  : A Shell script to convert observations for bias coorection of HAMSTER outputs into the monthly.
# Usage:
#       dos2unix convert_daily_observations.sh (one-time use)
#       chmod +x convert_daily_observations.sh (one-time use)
#       bash convert_daily_observations.sh et_shortveg gleamhybridv36 T_shortveg
# Parameters:
#       #! path name: p, e, et, et_tallveg, et_shortveg
#       #! path name: mswepv28, gleamhybridv36_oafluxv3_eraint, gleamhybridv36
#       #! file name: P, E, T, T_tallveg, T_shortveg
# Notes:
#       1. For simplicity in reporting subsequent results, we refer to a cropping year by the harvest year. For example, year 2001 indicates the 2000/2001 cropping year.
# ---
# Author: Hao Li, Hao.liwork@ugent.be
# Update: 2023/11/14
# --------------------------------------------------------------------------------

# --- Basics ---
set -u
set -e

type=$1    #! path name: p; e; et; et_tallveg; et_shortveg;
version=$2 #! path name: mswepv28; gleamhybridv36_oafluxv3_eraint; gleamhybridv36
prefix=$3  #! file name: P; E; T; T_tallveg; T_shortveg

# --- PATHs ---
ipath="/data/gent/vo/000/gvo00090/FLEXPART/observations/from_scratch/${type}_${version}_1deg"
opath="/data/gent/vo/000/gvo00090/vsc43765/Deforestation-Impacts-on-Climate/01-data/observations"

# --- Module ---
module purge
module load CDO/1.9.8-intel-2019b
module load NCO/5.0.6-intel-2019b

echo "--- ${type} ---"
mkdir -p ${opath}/${type}

echo "# --- Merge daily data ---"
if [[ ${type} == "e" ]]; then
    cdo -O -L -shifttime,-6hours -selvar,evaporation -mergetime ${ipath}/${prefix}_GLEAM*_1deg_daily_*.nc ${opath}/${type}/${prefix}_${version}_1deg_daily.nc
else
    cdo -O -L -mergetime ${ipath}/${prefix}_*_1deg_daily_*.nc ${opath}/${type}/${prefix}_${version}_1deg_daily.nc
fi

echo "# --- Resmaple it to monthly ---"
cdo -O -L -monsum ${opath}/${type}/${prefix}_${version}_1deg_daily.nc ${opath}/${type}/${prefix}_${version}_1deg_monthly.nc