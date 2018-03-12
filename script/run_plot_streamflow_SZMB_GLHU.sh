#!/bin/bash
if [ $# -lt 7 ]; then
    echo "arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir; work_dir; web_dir/{cycles,gifs}; cycle; plot_begin_hour; plot_end_hour"
    exit
fi

scriptdir=$1/ncl
cycledir=$2
workdir=$3
datadir="$1/data/"
consdir="$1/cons/"
webdir=$4
cycle=$5
plot_begin_hour=$6
plot_end_hour=$7

date
echo "scriptdir: $scriptdir"
echo "cycledir:  $cycledir"
echo "workdir:   $workdir"
echo "webdir:    $webdir"
echo "cycle:     $cycle"
echo "plot_begin_hour:  $plot_begin_hour"
if [ $plot_begin_hour -gt 0 ]; then
    echo "- Warning: usually plot_begin_hour should be <= 0 !!"
fi
echo "plot_end_hour: $plot_end_hour"
if [ $plot_end_hour -lt 0 ]; then
    echo "- Warning: usually plot_end_hour should be >=0 !!"
fi
#normal
test -d $workdir || mkdir -p $workdir
cd ${workdir}
#4D
echo "GLHU"
test -d GLHU || mkdir -p GLHU
cd GLHU
test -d before_overlay || mkdir -p before_overlay
cd before_overlay
echo "before_overlay"
$1/script/cpln_hydrofile_here.sh ${cycledir}/ CHRTOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
#D4: 2250x2250: 1352x1324+449+408  ; 676x662+225+204 => 678x591
#SZ: 2250x2250: 1352x920+449+609   ; 676x460+225+305 => 1080x625
#TG: 2250x2250: 1100x1480+570+320  ; 550x740+285+160 => 695x761
#GL: 2250x2250: 1210x1480+520+320  ; 605x740+260+160 =>  812x1037
#GLHU: 2250x2250; 1048x1490+600+310 => 550x795

ln -sf ${datadir}/geo_em.nc .
ln -sf ${scriptdir}/plot_streamflow_Customize_forTrans_noLegend2.ncl .
ln -sf ${consdir}/grads_rainbow2.txt .
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout_forStreamflow.ncl .
ln -sf ${consdir}/nodeidx_GLHU.txt .
echo ncl 'srcfilename="??????????00.CHRTOUT_DOMAIN1"' 'colorbar_maxvalue=50' 'dom_name="GLHU"' 'nodeidx_file="nodeidx_GLHU.txt"' 'lonlat_list="113.9752,114.0986,22.5904,22.7372"' plot_streamflow_Customize_forTrans_noLegend2.ncl  
ncl 'srcfilename="??????????00.CHRTOUT_DOMAIN1"' 'colorbar_maxvalue=50' 'dom_name="GLHU"' 'nodeidx_file="nodeidx_GLHU.txt"' 'lonlat_list="113.9752,114.0986,22.5904,22.7372"' plot_streamflow_Customize_forTrans_noLegend2.ncl &> log.plt
bash $1/script/convert_ps_to_png_vianode30.sh *.ps 
date
cd ..
echo "overlayGE &  cp to web"
test -d overlayGE || mkdir -p overlayGE
cd overlayGE
ln -sf $consdir/pngs/GLHU/background.png .
ln -sf $consdir/pngs/GLHU/legend.png .
for png in $(ls ../before_overlay/*.png); do
    convert +repage -transparent "rgb(255,255,255)" -crop 1048x1490+600+310  -resize 550x795! $png inter.png
    pngtitle=$(basename $png .png)
    convert -gravity south background.png inter.png -composite inter2.png
    convert -append inter2.png legend.png GE_${pngtitle}.png
    datx=$(echo $pngtitle | cut -d "_" -f 5)
    test -d "$webdir/cycles/$cycle/$datx" || mkdir -p "$webdir/cycles/$cycle/$datx" 
    echo cp GE_${pngtitle}.png $webdir/cycles/$cycle/$datx/GLHU_Streamflow.png
    cp GE_${pngtitle}.png $webdir/cycles/$cycle/$datx/GLHU_Streamflow.png
    test -d "$webdir/gifs/$datx" || mkdir -p "$webdir/gifs/$datx" 
    test -e "$webdir/gifs/$datx/GLHU_Streamflow.png" && rm -rf "$webdir/gifs/$datx/GLHU_Streamflow.png"
    echo cp GE_${pngtitle}.png $webdir/gifs/$datx/GLHU_Streamflow.png
    cp GE_${pngtitle}.png $webdir/gifs/$datx/GLHU_Streamflow.png
    cp inter.png $webdir/gifs/$datx/GLHU_Streamflow_White.png
    rm inter.png inter2.png
done
touch $workdir/finished.streamflow_GLHU
