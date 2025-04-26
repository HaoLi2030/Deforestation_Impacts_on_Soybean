#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Main script to extract trajectories from binary FLEXPART outputs
# 
# This file is part of HAMSTER, 
# originally created by Dominik Schumacher, Jessica Keune, Diego G. Miralles
# at the Hydro-Climate Extremes Lab, Department of Environment, Ghent University
# 
# https://github.com/h-cel/hamster
# 
# HAMSTER is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation v3.
#
# HAMSTER is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with HAMSTER. If not, see <http://www.gnu.org/licenses/>.
#

import argparse
import calendar
import csv
import fnmatch
import gzip
import imp
import math
import os
import random
import re
import struct
import sys
import time
import timeit
import warnings
from datetime import date, datetime, timedelta
import datetime as datetime
from functools import reduce
from math import acos, atan, atan2, cos, floor, sin, sqrt

import h5py
import netCDF4 as nc4
import numpy as np
import pandas as pd
from dateutil.relativedelta import relativedelta

from hamsterfunctions import *


def main_flex2traj(
    ryyyy, ayyyy, am, ad, dt, tml, maskfile, maskval, idir, odir, fout, fanndir, fisgz, tnparcel, verbose
):

    ###--- MISC ---################################################################
    logo = """ 
        Hello, user. 
        
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       %  __ _           ____  _              _  %
      %  / _| | _____  _|___ \| |_ _ __ __ _ (_)  %  
     %  | |_| |/ _ \ \/ / __) | __| '__/ _` || |   %
     %  |  _| |  __/>  < / __/| |_| | | (_| || |   %
      % |_| |_|\___/_/\_\_____|\__|_|  \__,_|/ |  %
       %                                    |__/ %                                     
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    """
    ###############################################################################
    ###--- SETUP ---###############################################################

    # ******************************************************************************
    ## UNCOMMENT line ---> variable not saved
    # full partposit
    selvars = np.asarray(
        [
            0,  # pid        |        [ ALWAYS ] * 0
            1,  # x          |        [ ALWAYS ] * 1
            2,  # y          |        [ ALWAYS ] * 2
            3,  # z          |        [ ALWAYS ] * 3
            # 4, # itramem    |        [ NEVER  ]
            5,  # oro        |        [ OPTIONAL ] # only needed for dry static energy
            # 6, # pv         |        [ OPTIONAL ]
            7,  # qq         |        [ ALWAYS ] * 4
            8,  # rho        |        [ ALWAYS ] * 5
            9,  # hmix       |        [ ALWAYS ] * 6
            # 10,# tropo      |        [ OPTIONAL ] * 7  # needed for droughtpropag
            11,  # temp       |        [ ALWAYS ] * 8
            # 12,# mass       |        [ NEVER! ]
        ]
    )
    #selvars = np.asarray(
    #    [
    #        0,  # pid        |        [ ALWAYS ] * 0
    #        1,  # x          |        [ ALWAYS ] * 1
    #        2,  # y          |        [ ALWAYS ] * 2
    #        3,  # z          |        [ ALWAYS ] * 3
    #        4,  # oro        |        [ OPTIONAL ] # only needed for dry static energy
    #        5,  # qq         |        [ ALWAYS ] * 4
    #        6,  # rho        |        [ ALWAYS ] * 5
    #        7,  # hmix       |        [ ALWAYS ] * 6
    #        # 8,# tropo      |        [ OPTIONAL ] * 7  # needed for droughtpropag
    #        9,  # temp       |        [ ALWAYS ] * 8
    #    ]
    #)
    # full partposit
    thevars = np.asarray(
        [
            "pid",
            "x",
            "y",
            "z",
            "itramem",
            "oro",
            "pv",
            "qv",
            "rho",
            "hmix",
            "tropo",
            "temp",
            "mass",
        ]
    )
    #thevars = np.asarray(
    #    [
    #        "pid",
    #        "x",
    #        "y",
    #        "z",
    #        "oro",
    #        "qv",
    #        "rho",
    #        "hmix",
    #        #"tropo",
    #        "temp",
    #    ]
    #)
    
    # ******************************************************************************

    # last day of month
    ed = int(calendar.monthrange(ayyyy, am)[1])

    dt_h = dt
    time_bgn = datetime.datetime(year=ayyyy, month=am, day=ad, hour=dt_h)
    # add one time step to handle end of month in same way as any other period
    time_end = datetime.datetime(
        year=ayyyy, month=am, day=ed, hour=24-dt_h
    ) + datetime.timedelta(hours=dt_h)
    # convert trajectory length from day to dt_h (!=6); +2 needed ;)
    # JK: TO BE CHECKED!!!
    ntraj = tml * (24 // dt_h) + 2

    ###############################################################################
    ###--- MAIN ---################################################################

    if verbose:
        print(logo)

    ##---0.) prepare directories
    if fanndir:
        idir = idir + "/" + str(ryyyy)
        #odir = odir + "/" + str(ryyyy)
    odir = odir + "/" + str(ryyyy)# JKe: keeping annual output structure for now
    if not os.path.exists(odir):  # could use isdir too
        os.makedirs(odir)

    ##---1.) load netCDF mask
    if maskfile is None or maskval == -999:
        mask = mlat = mlon = None
    else:
        mask, mlat, mlon = maskgrabber(maskfile)

    ##---2.) create datetime object (covering arrival period + trajectory length)
    fulltime_str = f2t_timelord(ntraj_d=tml, dt_h=dt_h, tbgn=time_bgn, tend=time_end)

    # ---3.) handle first step
    if verbose:
        print("\n---- Reading files to begin constructing trajectories ...\n")
    data, trajs = f2t_establisher(
        partdir=idir,
        selvars=selvars,
        time_str=fulltime_str[:ntraj],
        ryyyy=ryyyy,
        mask=mask,
        maskval=maskval,
        mlat=mlat,
        mlon=mlon,
        outdir=odir,
        fout=fout,
        fisgz=fisgz,
        tnparcel=tnparcel,
        verbose=verbose,
    )

    ##---4.) continue with next steps
    if verbose:
        print("\n\n---- Adding more files ... ")
    for ii in range(1, len(fulltime_str) - ntraj + 1):  # CAUTION: INDEXING from 1!
        data, trajs = f2t_ascender(
            data=data,
            partdir=idir,
            selvars=selvars,
            time_str=fulltime_str[ii : ntraj + ii],
            ryyyy=ryyyy,
            mask=mask,
            maskval=maskval,
            mlat=mlat,
            mlon=mlon,
            outdir=odir,
            fout=fout,
            fisgz=fisgz,
            verbose=verbose,
        )

    ##---5.) done
    if verbose:
        print(
            "\n\n---- Done! \n     Files with base '" + fout + "' written to:\n    ",
            odir + "/" + str(ryyyy),
        )
        print("     Dimensions: nstep x nparcel x nvar\n     Var order: ", end="")
        print(*thevars[selvars].tolist(), sep=", ")
        print("\n     All done!")
