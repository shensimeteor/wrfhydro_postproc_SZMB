#!/bin/sh
#arguments: hydro_root_dir/{ncl,data,cons}; cycle_dir(put all data there); work_dir; web_dir/{cycles,gifs}; cycle; begin hour plot (e.g. -6); plot_end_hour (e.g. 24)
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
#D4
echo "D4"
test -d D4 || mkdir -p D4
cd D4
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
#ln -sf ${consdir}/TG_*txt .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"D4\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo $cmd
bash -c "$cmd"
#rm -rf *LDASOUT_DOMAIN1
date
cd ..
#SZ
echo "SZ"
test -d SZ || mkdir -p SZ
cd SZ
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"SZ\"'  'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"'  plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
#rm -rf *LDASOUT_DOMAIN1
date
cd ..
#TG
echo TG
test -d TG || mkdir -p TG
cd TG
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/TG*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"TG\"' 'lonlat_list=\"113.843,113.936,22.595,22.7\"' 'add_chan_border=\"TG\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
date
cd ..
#GL
echo GL
test -d GL || mkdir -p GL
cd GL
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/GL*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"GL\"' 'lonlat_list=\"113.955,114.113,22.577,22.740\"' 'add_chan_border=\"GL\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
#BAB
echo BAB
test -d BAB || mkdir -p BAB
cd BAB
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/BAB*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"BAB\"' 'lonlat_list=\"113.753,113.896,22.666,22.795\"' 'add_chan_border=\"BAB\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
touch $workdir/finished.evapor
date


