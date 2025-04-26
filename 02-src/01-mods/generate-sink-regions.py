#!/usr/bin/env python3
#! Description: This script is used to generate the sink regions (NetCDF) from the shapefiles using the package 'regionmask'. 
# Author: Hao Li, Hao.Liwork@ugent.be
# Date: 2023/07/07

#%% --- Import packages
import geopandas as gpd 
import regionmask
import xarray as xr 
import numpy as np 
import pandas as pd

#%% --- Load shapefiles
# global regions
shp = gpd.read_file('../../01-data/regions/bra_adm_ibge_2020_shp/bra_admbnda_adm1_ibge_2020.shp')

#%% --- Create the dataframe
# add a new column in the dataframe
PCODE = []
for i in range(shp.shape[0]):
        PCODE.append(int(shp['ADM1_PCODE'][i][2:]))
shp['PCODE'] = PCODE
# define the indices
NE1_index = [24, 25]
NE2_index = [26, 27, 28]
SE1_index = [32, 33]
CW1_index = [53, 52]
# index the new values
NE1 = shp[shp['PCODE'].isin(NE1_index)]
NE2 = shp[shp['PCODE'].isin(NE2_index)]
SW1 = shp[shp['PCODE'].isin(SE1_index)]
CW1 = shp[shp['PCODE'].isin(CW1_index)]
# dissolve the data
NE1 = NE1.dissolve(by='ADM0_EN', as_index=False)
NE2 = NE2.dissolve(by='ADM0_EN', as_index=False)
SW1 = SW1.dissolve(by='ADM0_EN', as_index=False)
CW1 = CW1.dissolve(by='ADM0_EN', as_index=False)
# other unchanged regions
OTH = shp[~shp['PCODE'].isin(NE1_index + NE2_index + SE1_index + CW1_index)]
# generate the new dataframe
gdf = pd.concat([OTH, NE1, NE2, SW1, CW1])

gdf = gdf.set_index('PCODE') # new dataframe

# output the merged shapefile 
gdf.to_file('./Brazil_states.shp')

# output the csv
out = gdf[['ADM0_EN','ADM1_PT','ADM1_PCODE']]
#out.to_csv('./regions.csv') # we need the values in running HAMSTER.

#%% --- Generate the masks
lon = np.arange(-180, 180, 1)
lat = np.arange(-90 , 91 , 1)
mask_states = regionmask.mask_geopandas(gdf, lon, lat)
#! Comment: The package 'regionmask' numbers the regions by taking `geodataframe.index.values`. Thus, you can access the o2 regions over HMA through indexing the numbers from 48 to 62.

#--- Export the masks
mask_states.to_netcdf('./mask_states_10deg.nc', encoding={'lon': {'dtype': 'int16'}, 'lat': {'dtype': 'int16'}})

#%% --- Plot the region
import proplot as pplt 

fig, ax = pplt.subplots(ncols=1, nrows=1, refaspect=3/4, journal='nat1', proj='cyl')

ax.stock_img()

# --- format the figure
ax.format(
        # elements      
        coast=True, coastcolor='black', coastlinewidth=0.5, coastzorder=3,
        # grid lines
        labels=True, gridminor=True,
        latlines=5, lonlines=5,
        # space extents
        lonlim=(-90, -30), latlim=(-60, 15),
        )

# generate the grid
nx = np.linspace(-180,179,360)
ny = np.linspace(-90, 90, 181)
nx, ny = np.meshgrid(nx, ny)

# plot the map
map1 = ax.pcolor(nx, ny, mask_states, levels=np.linspace(0, 60, 31), cmap='Fire', extend='both', zorder=2)

gdf.boundary.plot(ax=ax, color='k', linewidth=1)

ax.colorbar(map1, loc='b', length=0.90, extendsize='1.7em', ticks=6)