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
echo "D4"
test -d D4 || mkdir -p D4
cd D4
$1/script/cpln_hydrofile_here.sh ${cycledir}/ RTOUT_DOMAIN1 ln $cycle -6 24
ln -sf ${scriptdir}/plot_tilevars.ncl .
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${scriptdir}/any2d_lonlat_to_ij.ncl .
ln -sf $scriptdir/smooth_convolution.ncl .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/TG*.txt .
cmd="ncl 'srcfilename=\"*.RTOUT_DOMAIN1\"' 'dom_name=\"D4\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_tilevars.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
date
#rm -rf *.RTOUT_DOMAIN1
cd ..
##SZ
echo "SZ"
test -d SZ || mkdir -p SZ
cd SZ
$1/script/cpln_hydrofile_here.sh ${cycledir}/ RTOUT_DOMAIN1 ln $cycle -6 24
ln -sf ${scriptdir}/plot_tilevars.ncl .
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${scriptdir}/any2d_lonlat_to_ij.ncl .
ln -sf $scriptdir/smooth_convolution.ncl .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/GL*.txt .
#ncl 'srcfilename="*.RTOUT_DOMAIN1"' 'dom_name="SZ"' 'lonlat_list="113.75,114.7,22.4,22.95"' plot_tilevars.ncl
cmd="ncl 'srcfilename=\"*.RTOUT_DOMAIN1\"' 'dom_name=\"SZ\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_tilevars.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
date
#rm -rf *RTOUT_DOMAIN1
cd ..
#TG
echo "TG"
test -d TG || mkdir -p TG
cd TG
$1/script/cpln_hydrofile_here.sh ${cycledir}/ RTOUT_DOMAIN1 ln $cycle -6 24
ln -sf ${scriptdir}/plot_tilevars.ncl .
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${scriptdir}/any2d_lonlat_to_ij.ncl .
ln -sf $scriptdir/smooth_convolution.ncl .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/TG*.txt .
cmd="ncl 'srcfilename=\"*.RTOUT_DOMAIN1\"' 'dom_name=\"TG\"' 'lonlat_list=\"113.843,113.936,22.595,22.7\"' 'add_chan_border=\"TGchan\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_tilevars.ncl"
bash -c "$cmd"
#rm -rf *.RTOUT_DOMAIN1
date
cd ..
#GL
echo "GL"
test -d GL || mkdir -p GL
cd GL
$1/script/cpln_hydrofile_here.sh ${cycledir}/ RTOUT_DOMAIN1 ln $cycle -6 24
ln -sf ${scriptdir}/plot_tilevars.ncl .
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${scriptdir}/any2d_lonlat_to_ij.ncl .
ln -sf $scriptdir/smooth_convolution.ncl .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/GL*.txt .
cmd="ncl 'srcfilename=\"*.RTOUT_DOMAIN1\"' 'dom_name=\"GL\"' 'lonlat_list=\"113.955,114.113,22.577,22.740\"' 'add_chan_border=\"GL\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_tilevars.ncl"
bash -c "$cmd"
#rm -rf *RTOUT_DOMAIN1
date



