#!/bin/bash

#
# Transform features (using jq)
#

# Stop on any error
set -e

jq -c --seq '
.properties 
|=
with_entries(
    select(
        [.key]
        |
        inside(
            [
                "railway",
                "usage",
                "service",
                "name",
                "name:en",
                "railway:ref",
                "railway:preserved",
                "gauge",
                "highspeed",
                "maxspeed",
                "passenger_lines",
                "electrified",
                "voltage",
                "frequency",
                "tunnel",
                "bridge",
                "embankment",
                "cutting",
                "station",
                "public_transport",
                "network",
                "operator",
                "ref",
                "uic_ref",
                "wikidata"
            ]
        )
    )
)
|
select(.properties | length > 0)
|
if
    (.properties.railway == "rail" and .properties.usage == "main" and (.properties | has("service") != true) and (.properties | has("railway:preserved") != true))
then
    .tippecanoe.minzoom = 0
else
    .tippecanoe.minzoom = 9
end
'
