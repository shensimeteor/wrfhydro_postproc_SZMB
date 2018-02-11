#!/bin/bash
if [ $# -lt 5 ]; then
    echo "arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir; work_dir; web_dir/{cycles,gifs}; cycle"
    exit
fi

scriptdir=$1/ncl
cycledir=$2
workdir=$3
datadir="$1/data/"
consdir="$1/cons/"
webdir=$4
cycle=$5

date
echo "scriptdir: $scriptdir"
echo "cycledir:  $cycledir"
echo "workdir:   $workdir"
echo "webdir:    $webdir"
echo "cycle:     $cycle"
echo ""
#normal
test -d $workdir || mkdir -p $workdir
cd ${workdir}
#4D
echo "SZ"
test -d SZ || mkdir -p SZ
cd SZ
test -d before_overlay || mkdir -p before_overlay
cd before_overlay
echo "before_overlay"
$1/script/cpln_hydrofile_here.sh ${cycledir}/ CHRTOUT_DOMAIN1 ln $cycle -6 24
#D4: 2250x2250: 1352x1324+449+408  ; 676x662+225+204 => 678x591
#SZ: 2250x2250: 1352x920+449+609   ; 676x460+225+305 => 1080x625
#TG: 2250x2250: 1100x1480+570+320  ; 550x740+285+160 => 695x761
#GL: 2250x2250: 1210x1480+520+320  ; 605x740+260+160 =>  812x1037

ln -sf ${datadir}/geo_em.nc .
ln -sf ${scriptdir}/plot_streamflow_Customize_forTrans_noLegend2.ncl .
ln -sf ${consdir}/grads_rainbow2.txt .
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout_forStreamflow.ncl .
echo ncl 'srcfilename="??????????00.CHRTOUT_DOMAIN1"' 'colorbar_maxvalue=100' 'dom_name="SZ"' plot_streamflow_Customize_forTrans_noLegend2.ncl 
ncl 'srcfilename="??????????00.CHRTOUT_DOMAIN1"' 'colorbar_maxvalue=100'  'dom_name="SZ"' plot_streamflow_Customize_forTrans_noLegend2.ncl  &> log.plot
bash $1/script/convert_ps_to_png_vianode30.sh *.ps 
date
cd ..
echo "overlayGE &  cp to web"
test -d overlayGE || mkdir -p overlayGE
cd overlayGE
ln -sf $consdir/pngs/SZ/background.png .
ln -sf $consdir/pngs/SZ/legend.png .
for png in $(ls ../before_overlay/*.png); do
    convert +repage -transparent "rgb(255,255,255)" -crop 1352x920+449+609  -resize 1080x706! $png inter.png
    pngtitle=$(basename $png .png)
    convert -gravity south background.png inter.png -composite inter2.png
    convert -append inter2.png legend.png GE_${pngtitle}.png
    datx=$(echo $pngtitle | cut -d "_" -f 5)
    test -d "$webdir/cycles/$cycle/$datx" || mkdir -p "$webdir/cycles/$cycle/$datx" 
    echo cp GE_${pngtitle}.png $webdir/cycles/$cycle/$datx/d5_Streamflow.png
    cp GE_${pngtitle}.png $webdir/cycles/$cycle/$datx/d5_Streamflow.png
    test -d "$webdir/gifs/$datx" || mkdir -p "$webdir/gifs/$datx" 
    test -e "$webdir/gifs/$datx/d5_Streamflow.png" && rm -rf "$webdir/gifs/$datx/d5_Streamflow.png"
    echo cp GE_${pngtitle}.png $webdir/gifs/$datx/d5_Streamflow.png
    cp GE_${pngtitle}.png $webdir/gifs/$datx/d5_Streamflow.png
    rm inter.png inter2.png
done
touch $workdir/finished.streamflow_SZ
