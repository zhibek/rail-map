#!/bin/bash

#
# Build rail tiles (using Osmium & Tippecanoe)
#

# Stop on any error
set -e

# Declare constants
EXEC=""
DOCKER_EXEC="docker run --rm --user $UID:$GID -v "$(pwd):/workspace" -w /workspace zhibek/osm-toolbox:1.3.0"

# Accept input variables from command flags
while getopts a:d: flag
do
    case "${flag}" in
        a) AREA=${OPTARG};;
        d) DOCKER=${OPTARG};;
    esac
done

# Fallback to environment vars or defaults for input variables
AREA="${AREA:=}" # Required. Example: great_britain OR greater_london
DOCKER="${DOCKER:=false}" # Default: False (i.e. Run without Docker)

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
-o "./files/$AREA.osm.pbf"

echo "* Extract railway data with *Osmium*..."
$EXEC osm-filter \
-f railway \
-a "$AREA" \
-i "./files/$AREA.osm.pbf" \
-o ./files/$AREA-railways.osm.pbf
ls -lah ./files/$AREA-railways.osm.pbf

echo "* Export OSM output to GeoJson using *Osmium*..."
$EXEC osmium export \
./files/$AREA-railways.osm.pbf \
-o ./files/$AREA-railways.geojson \
-f geojsonseq \
--overwrite
ls -lah ./files/$AREA-railways.geojson
rm ./files/$AREA-railways.osm.pbf

echo "* Transforming features using *jq*"
$(dirname "$0")/transform-features.sh < ./files/$AREA-railways.geojson > ./files/$AREA-railways-transformed.geojson
ls -lah ./files/$AREA-railways-transformed.geojson
rm -f ./files/$AREA-railways.geojson

echo "* Convert GeoJson to PMTiles using *Tippecanoe*..."
$EXEC tippecanoe \
-z12 \
-P \
-L railways:./files/$AREA-railways-transformed.geojson \
-o "./files/$AREA-railways.pmtiles" \
--drop-densest-as-needed \
--extend-zooms-if-still-dropping \
--force
ls -lah ./files/$AREA-railways.pmtiles
rm -f ./files/$AREA-railways-transformed.geojson

# Confirm completion
echo "* Build completed!"
