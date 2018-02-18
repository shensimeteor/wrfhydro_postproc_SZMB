#!/bin/bash
if [ $# -lt 3 ]; then
    echo "<usage>: $0  <gebg_noWhiteHead_png>  <white head height: integer> <output_gebg_png>"
    exit 2
fi

png=$1
hgt=$2
out=$3

wdth=$(identify $png | sed "s/^.*PNG *//g" | cut -d "x" -f 1)
echo "convert -size ${wdth}x${hgt} xc:white white.png"
convert -size ${wdth}x${hgt} xc:white white.png
echo "convert -append white.png $png $out"
convert -append white.png $png $out
