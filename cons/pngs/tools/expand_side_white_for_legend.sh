#!/bin/bash
if [ $# -lt 3 ]; then
    echo "<usage> $0  <original_legend_png>  <expected width, integer>  <output_png>"
    exit 
fi

png=$1
wdth=$2
out=$3

png_wdth=$(identify $png | sed "s/^.*PNG *//g" | cut -d "x" -f 1)
if [ $png_wdth -gt $wdth ]; then
    echo "
