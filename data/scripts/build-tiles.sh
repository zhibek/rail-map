#!/bin/bash

#
# Build rail tiles (using Osmium & Tippecanoe)
#

# Stop on any error
set -e

# Declare constants
SHELL_EXEC="bash"
DOCKER_EXEC="docker run --rm --user $UID:$GID -v "$(pwd):/workspace" -w /workspace zhibek/osm-toolbox:1.2.0"
EXEC=$SHELL_EXEC

# Accept input variables from command flags
while getopts a:d: flag
do
    case "${flag}" in
        a) AREA=${OPTARG};;
        d) DOCKER=${OPTARG};;
    esac
done

# Fallback to environment vars or defaults for input variables
AREA="${AREA:=}" # Required. Example: greater_london
DOCKER="${DOCKER:=true}" # Default: True (i.e. Run with Docker)

# Validate input variables are set
[ -z "$AREA" ] && echo "AREA must be set, either as an environment variable or using -a command flag." && exit 1;

# Use Docker to execute script if $DOCKER is set
if [ "$DOCKER" == true ]
then
  EXEC=$DOCKER_EXEC
fi

echo "* Download OSM data for area..."
$EXEC osm-download \
-a "$AREA" \
-o "./sources/$AREA.osm.pbf"

echo "* Extract railway data with *Osmium*..."
$EXEC osm-filter \
-f railway \
-a "$AREA" \
-i "./sources/$AREA.osm.pbf" \
-o ./tmp/$AREA-railways.osm.pbf
ls -lah ./tmp/$AREA-railways.osm.pbf

echo "* Export OSM output to GeoJson using *Osmium*..."
$EXEC osm-to-geojson \
-i ./tmp/$AREA-railways.osm.pbf \
-o ./tmp/$AREA-railways.geojson
ls -lah ./tmp/$AREA-railways.geojson
rm -f ./tmp/$AREA-railways.osm.pbf

echo "* Convert GeoJson to PMTiles using *Tippecanoe*..."
$EXEC tippecanoe -z12 \
-o "./$AREA-railways.pmtiles" \
-L railways:./tmp/$AREA-railways.geojson \
--drop-densest-as-needed \
--force
ls -lah ./$AREA-railways.pmtiles
rm -f ./tmp/$AREA-railways.geojson

# Confirm completion
echo "* Build completed!"
