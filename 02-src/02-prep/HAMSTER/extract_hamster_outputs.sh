#!/bin/bash -l

### to submit this job, you have to pass a few variables:
###  > qsub -v mval=58,veg=land,var=E2P_EPs extract_hamster_outputs.sh

#PBS -N post_hmaster
#PBS -l nodes=1:ppn=1
#PBS -l walltime=00:03:00
#PBS -l mem=10gb
#PBS -m a

set -x
set -u
set -e
cd $PBS_O_WORKDIR

# --- Module ---
module purge
module load CDO/1.9.8-intel-2019b

# SETTINGS
ipath='/data/gent/vo/000/gvo00090/vsc43765/Deforestation-Impacts-on-Climate/02-src/01-mods/output/'
opath='/data/gent/vo/000/gvo00090/vsc43765/Deforestation-Impacts-on-Climate/01-data/HAMSTER'

mkdir -p ${opath}/BR${mval}/${var}_${veg}

# # Extract the specific variable
# for yyyy in $(seq 1981 1 2018); do
#     for m in $(seq 1 1 12); do
#         mm=$(printf "%02d" $m)
#         # --- Extract the selected variable ---
#         cdo -O --no_history -selvar,${var} ${ipath}/BR${mval}/03_bias/${veg}/ALLPBL_biascor-attr_*_${yyyy}-${mm}.nc ${opath}/BR${mval}/${var}_${veg}/${var}_${veg}_${yyyy}-${mm}.nc
#     done
# done

# # Merge the dataset
# cdo -O --no_history -mergetime ${opath}/BR${mval}/${var}_${veg}/${var}_${veg}*.nc ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_daily_${var}.nc

# Resample the data
if [[ ${var} == "Had_Hs" ]]; then
    echo "# --- Resmaple it to monthly ---"
    cdo -O --no_history -L -setreftime,1981-01-01,00:00:00,days -settaxis,1981-01-15,00:00,1month -monavg ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_daily_${var}.nc ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_monthly_${var}.nc

    echo "# --- Resmaple it to yearly ---"
    cdo -O --no_history -L -setreftime,1981-01-01,00:00:00,days -settaxis,1981-01-15,00:00,1year -yearavg ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_daily_${var}.nc ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_yearly_${var}.nc

else
    echo "# --- Resmaple it to monthly ---"
    cdo -O --no_history -L -setreftime,1981-01-01,00:00:00,days -settaxis,1981-01-15,00:00,1month -monsum ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_daily_${var}.nc ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_monthly_${var}.nc

    echo "# --- Resmaple it to yearly ---"
    cdo -O --no_history -L -setreftime,1981-01-01,00:00:00,days -settaxis,1981-01-15,00:00,1year -yearsum ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_daily_${var}.nc ${opath}/BR${mval}/${var}_${veg}/HAMSTER_1deg_yearly_${var}.nc
fi

# Remove the data
# rm ${opath}/BR${mval}/${var}_${veg}/${var}_*.nc

echo "End of jobscript!"
# --- END MAIN ---

exit
