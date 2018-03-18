#!/bin/sh
<<<<<<< HEAD
#plot (2 dom + 7 subdom):  D4/SZ(d5),  TGSK/GLHU/LGHU/PSHU/MZHU/SZSK/SZFT
=======
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
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
<<<<<<< HEAD
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
=======
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"D4\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo $cmd
bash -c "$cmd"
#rm -rf *LDASOUT_DOMAIN1
date
cd ..
#SZ
echo "SZ"
test -d SZ || mkdir -p SZ
cd SZ
<<<<<<< HEAD
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
=======
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"SZ\"'  'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"'  plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
#rm -rf *LDASOUT_DOMAIN1
date
cd ..
<<<<<<< HEAD
#TGSK
echo TGSK
test -d TGSK || mkdir -p TGSK
cd TGSK
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
=======
#TG
echo TG
test -d TG || mkdir -p TG
cd TG
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/TGSK*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
<<<<<<< HEAD
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"TGSK\"' 'lonlat_list=\"113.8289,113.9888,22.5847,22.7132\"' 'add_chan_border=\"TGSK\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
=======
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"TG\"' 'lonlat_list=\"113.843,113.936,22.595,22.7\"' 'add_chan_border=\"TG\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
echo "$cmd"
bash -c "$cmd"
date
cd ..
<<<<<<< HEAD
#GLHU
echo GLHU
test -d GLHU || mkdir -p GLHU
cd GLHU
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/GLHU*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"GLHU\"' 'lonlat_list=\"113.9752,114.0986,22.5904,22.7372\"' 'add_chan_border=\"GLHU\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
#LGHU
echo LGHU
test -d LGHU || mkdir -p LGHU
cd LGHU
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/LGHU*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"LGHU\"' 'lonlat_list=\"114.1710,114.3132,22.6744,22.8033\"' 'add_chan_border=\"LGHU\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
#PSHU
echo PSHU
test -d PSHU || mkdir -p PSHU
cd PSHU
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
=======
#GL
echo GL
test -d GL || mkdir -p GL
cd GL
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/PSHU*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"PSHU\"' 'lonlat_list=\"114.2565,114.3828,22.6119,22.7238\"' 'add_chan_border=\"PSHU\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
<<<<<<< HEAD
#MZHU
echo MZHU
test -d MZHU || mkdir -p MZHU
cd MZHU
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
=======
#BAB
echo BAB
test -d BAB || mkdir -p BAB
cd BAB
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN1 ln $cycle $plot_begin_hour $plot_end_hour
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
<<<<<<< HEAD
ln -sf ${consdir}/MZHU*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"MZHU\"' 'lonlat_list=\"113.7877,113.9444,22.6994,22.8472\"' 'add_chan_border=\"MZHU\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
#SZSK
echo SZSK
test -d SZSK || mkdir -p SZSK
cd SZSK
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/SZSK*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"SZSK\"' 'lonlat_list=\"114.0755,114.2208,22.5472,22.6607\"' 'add_chan_border=\"SZSK\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
#SZFT
echo SZFT
test -d SZFT || mkdir -p SZFT
cd SZFT
echo $1/script/cpln_hydrofile_here.sh ${cycledir}/ LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
$1/script/cpln_hydrofile_here.sh ${cycledir} LDASOUT_DOMAIN6 ln $cycle $plot_begin_hour $plot_end_hour
ln -sf ${scriptdir}/plot_evapor_Customize.ncl
ln -sf ${scriptdir}/gsn_add_shapefile_polylines_for_v600.ncl .
ln -sf ${datadir}/SZDistrictSurface.nc .
ln -sf ${datadir}/geo_em.nc .
ln -sf ${consdir}/SZFT*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN*\"' 'dom_name=\"SZFT\"' 'lonlat_list=\"114.0060,114.1238,22.5021,22.5856\"' 'add_chan_border=\"SZFT\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..

##end
=======
ln -sf ${consdir}/BAB*.txt .
ln -sf $scriptdir/ncl_future_func.ncl .
ln -sf $scriptdir/convert_and_copyout.ncl .
cmd="ncl 'srcfilename=\"*.LDASOUT_DOMAIN1\"' 'dom_name=\"BAB\"' 'lonlat_list=\"113.753,113.896,22.666,22.795\"' 'add_chan_border=\"BAB\"' 'copydir_list=\"$webdir/cycles/$cycle,$webdir/gifs\"' plot_evapor_Customize.ncl >& log.plot"
echo "$cmd"
bash -c "$cmd"
cd ..
>>>>>>> 65c70d25852190239e9e016a12df0a38a611cb68
touch $workdir/finished.evapor
date
