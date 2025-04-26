#!/bin/bash -l

### to submit this job, you have to pass a few variables:
###  > qsub -v mval=58,mstart=1,mend=12 -t 2010-2010 run_hamster_yyyymm.sh

#PBS -N forest_jobs
#PBS -l nodes=1:ppn=1
#PBS -l walltime=30:00:00
#PBS -l mem=20gb
#PBS -m bea

set -x
set -u
set -e
cd $PBS_O_WORKDIR

# load the modules
module load netcdf4-python/1.5.3-intel-2019b-Python-3.7.4
module load h5py/2.10.0-intel-2019b-Python-3.7.4

# SETTINGS
yyyy=${PBS_ARRAYID}

# Main path
cd /scratch/gent/vo/000/gvo00090/vsc43765/Deforestation-Impacts-on-Climate/02-src/01-mods/hamster-1.2.1/src

rpath="/scratch/gent/vo/000/gvo00090/vsc43765/Deforestation-Impacts-on-Climate/02-src/01-mods/output/BR-${mval}"

# creating paths_RGI_mval.txt specific for the mask value and the region
#  - e.g. paths_RGI_59.nc refers to the mask value '59' (West Himalaya)
#  - automatically creating it from a template (paths.tmp), replacing placeholder
sleep 10

echo "Creating path files"
# Land
pfileL="paths_land_${mval}.txt"
cp -u paths_land.tmp $pfileL
sed -i -e "s/__MVAL__/${mval}/g" $pfileL
# Tall
pfileT="paths_tall_${mval}.txt"
cp -u paths_tall.tmp $pfileT
sed -i -e "s/__MVAL__/${mval}/g" $pfileT
# Short
pfileS="paths_short_${mval}.txt"
cp -u paths_short.tmp $pfileS
sed -i -e "s/__MVAL__/${mval}/g" $pfileS

sleep 1

# this path has to be in paths_mval.txt
#rpath=$(sed -n '7p' <paths_RGI_${mval}.txt | sed 's/path_orig = "//' | sed 's/orig"//')

# --- START MAIN ---

for m in $(seq $mstart 1 $mend); do

    echo "--------------------"
    echo "--------------------"
    echo "Processing: $yyyy-$m"
    echo "--------------------"
    echo "--------------------"

    echo "Getting data from the archive"
    time ./untar_flexpart_yyyymm.sh $yyyy $m $rpath/orig

    echo "flex2traj: extracting trajectories"
    time python main.py --steps 0 --ayyyy $yyyy --ryyyy $yyyy -am $m --ctraj_len 16 --maskval $mval --pathfile $pfileL --fisgz False --maxparcel 3000001 --parcelmass 1699257000000

    echo "hamster: attribution"
    time python main.py --steps 2 --ayyyy $yyyy --ryyyy $yyyy --am $m --ctraj_len 15 --maskval $mval --cpbl_strict 1 --cpbl_method "max" --cevap_dqv 0 --cheat_dtemp 0 --expid "ALLPBL" --pathfile $pfileL --fisgz False --maxparcel 3000001 --parcelmass 1699257000000

    echo "hamster: bias-correction for Land"
    time python main.py --steps 3 --ayyyy $yyyy --ryyyy $yyyy --am $m --ctraj_len 15 --maskval $mval --cpbl_strict 1 --cpbl_method "max" --cevap_dqv 0 --cheat_dtemp 0 --expid "ALLPBL" --bc_t2p_ep True --eref_data others --pref_data others --href_data others --writestats True --bc_useattp True --write_month False --pathfile $pfileL --fisgz False --maxparcel 3000001 --parcelmass 1699257000000

    echo "hamster: bias-correction for Trees"
    time python main.py --steps 3 --ayyyy $yyyy --ryyyy $yyyy --am $m --ctraj_len 15 --maskval $mval --cpbl_strict 1 --cpbl_method "max" --cevap_dqv 0 --cheat_dtemp 0 --expid "ALLPBL" --bc_t2p_ep True --eref_data others --pref_data others --href_data others --writestats True --bc_useattp True --write_month False --pathfile $pfileT --fisgz False --maxparcel 3000001 --parcelmass 1699257000000

    echo "hamster: bias-correction for Short Veg."
    time python main.py --steps 3 --ayyyy $yyyy --ryyyy $yyyy --am $m --ctraj_len 15 --maskval $mval --cpbl_strict 1 --cpbl_method "max" --cevap_dqv 0 --cheat_dtemp 0 --expid "ALLPBL" --bc_t2p_ep True --eref_data others --pref_data others --href_data others --writestats True --bc_useattp True --write_month False --pathfile $pfileS --fisgz False --maxparcel 3000001 --parcelmass 1699257000000

    echo "remove other files"
    rm $rpath/orig/$yyyy/partposit*
    rm $rpath/00_f2t/$yyyy/*.h5
    rm $rpath/02_attr/ALLPBL_attr*.nc

    echo "--------------------"
    echo "--------------------"
    echo "Done"
    echo "--------------------"
    echo "--------------------"

done

echo "End of jobscript!"
# --- END MAIN ---

exit
