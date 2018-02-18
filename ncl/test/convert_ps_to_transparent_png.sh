#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Usage:  convert_ps_to_transparent_png.sh <input_ps> <output_transparent_png>"
    exit
fi
convert -trim +repage -density 300% -transparent "rgb(255,255,255)"  $1  $2
