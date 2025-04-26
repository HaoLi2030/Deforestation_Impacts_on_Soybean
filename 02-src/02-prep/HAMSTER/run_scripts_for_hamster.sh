#!/bin/bash -l

for mval in 11 12 13 14 15 16 17 21 22 23 25 27 29 31 32 35 41 42 43 50 51 53; do
    # E2P
    qsub -v mval=${mval},veg=land,var=E2P_EPs extract_hamster_outputs.sh
    # T2P
    qsub -v mval=${mval},veg=land,var=T2P_EPs extract_hamster_outputs.sh
    # Had
    qsub -v mval=${mval},veg=land,var=Had_Hs extract_hamster_outputs.sh
    # T2P: Trees
    qsub -v mval=${mval},veg=tall,var=T2P_EPs extract_hamster_outputs.sh
    # T2P: Short Veg.
    qsub -v mval=${mval},veg=short,var=T2P_EPs extract_hamster_outputs.sh
done
