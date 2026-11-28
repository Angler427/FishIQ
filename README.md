# FishIQ

An iOS app for exploring freshwater lakes, checking fishing conditions, and logging catches.

## Setup

1. Open `fishingIQ.xcodeproj` in Xcode.
2. Copy `Config/Secrets.swift.example` to `fishingIQ/Secrets.swift`.
3. Paste your [MapTiler](https://cloud.maptiler.com/account/keys/) API key into `fishingIQ/Secrets.swift`.
   That file is git-ignored, so the key stays off GitHub.
4. Build and run.

## Data sources

- Lake and river outlines: USGS 3D Hydrography Program (3DHP)
- Weather and historical weather: Open-Meteo
- Basemaps: MapTiler (via MapLibre)
- Bathymetry: Waukesha County GIS
