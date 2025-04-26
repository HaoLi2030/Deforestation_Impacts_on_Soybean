# Deforestation_Impacts_on_Soybean

This repository contains the code and documentation for the research, which investigates the cascading impacts of deforestation-driven tree evaporation declines on regional precipitation and agricultural productivity in Brazil.

## Repository Structure

```
├── 01-data/               # Data files used in the analysis
│   ├── Climate/           # Climate data
│   ├── Soy_Yield/         # Soybean yield statistics
│   ├── MIRCA2000/         # Soybean harvest area
│   ├── Political_Units/   # Political units
│   └── HAMSTER/           # Moisture source tracking
│
├── 02-src/                # Source code
│   ├── 01-mods/           # Atmospheric moisture tracking code
│   ├── 02-prep/           # Preprocessing codes
│   └── codes/             # Analysis scripts for result interpretation
│
├── 03-doc/                # Documentation
│   ├── manuscript/        # Manuscript drafts and final version
│   └── figures/           # High-resolution figures for publication
│
└── README.md              # Main repository documentation
```

## Data Availability

The complete dataset used in this study is currently stored on High-Performance Computing (HPC) infrastructure. The first author is in the process of migrating the data to public repositories for broader accessibility.

For the time being, the following publicly available datasets were used in our analysis:

* Soybean yield statistics: https://www.ibge.gov.br
* Harvest area data: https://www.dante-project.org/datasets/mirca2K
* MEaSUREs Vegetation Continuous Fields: https://lpdaac.usgs.gov/products/vcf5kyrv001
* GLEAM evaporation data: https://www.gleam.eu
* OAFlux data: https://oaflux.whoi.edu/data-access
* ERA reanalysis data: https://cds.climate.copernicus.eu/cdsapp#!/dataset
* MSWEP precipitation data: http://www.gloh2o.org
