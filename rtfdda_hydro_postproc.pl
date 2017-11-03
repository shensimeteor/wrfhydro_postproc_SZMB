#/usr/bin/perl
if (! $ARGV[0] || $ARGV[0] eq "--" || $ARGV[0] eq "-h") {
   print "rtfdda_hydro_postproc.pl  <-id GMID>  <-m MEMBER>  <-c cycle | -o offset_hr> \n";
   exit(-1);
}else{
    $length = @ARGV;
    $i = 0;
    for($i = 0; $i < $length; $i++){
        if ($ARGV[$i] eq "--"){
            last;
        }elsif ($ARGV[$i] eq "-c"){
            $THIS_CYCLE = $ARGV[$i+1];
        }elsif ($ARGV[$i] eq "-o"){
            $OFFSET = $ARGV[$i+1];
            $ttime = time - $OFFSET *3600;
            ($sec,$mm,$hh,$dd,$mo,$yy,@_) = gmtime($ttime);
            if ($yy<50){ $yy+=2000; } else { $yy+=1900; }
            $THIS_CYCLE = sprintf("%04d%02d%02d%02d",$yy,$mo+1,$dd,$hh);
        }elsif ($ARGV[$i] eq "-m"){
            $MEM_NAME = $ARGV[$i+1];
        }elsif ($ARGV[$i] eq "-id"){
            $JOB_ID = $ARGV[$i+1];
        }else{
            next;
        }
    }
}
if (!"$THIS_CYCLE" || !"$MEM_NAME" || !"$JOB_ID") { 
     print "rtfdda_hydro_postproc.pl  <-id GMID>  <-m MEMBER>  <-c cycle | -o offset_hr> \n";
     exit(-1);
}

$GMODIR="$ENV{HOME}/data/GMODJOBS/$JOB_ID/";
$HYDRO_ROOT="$GMODDIR/hydro_postproc/";
$CYCLE_DIR="$ENV{HOME}/data/cycles/$JOB_ID/hydro/cycles/$MEM_NAME/$THIS_CYCLE";
$WEB_DIR="$ENV{HOME}/data/cycles/$JOB_ID/$MEM_NAME/postprocs/web";
$workdir="/dev/shm/hydro_postproc/$JOB_ID/$MEM_NAME/$THIS_CYCLE";
system("date");
print("cycle: $THIS_CYCLE\n");
print("workdir: $workdir\n");
#wait for hydro files

#cp to workdir
system("test -d $workdir/cycledata || mkdir -p $workdir/cycledata");
if ( -e "$workdir/cycledata/flag.copy") {
    print("hydro data already copied, skip \n");
}else{
    print("to copy CYCLE_DATA to workdir");
    chdir("$workdir/cycledata");
    system("ln -sf $CYCLE_DIR/forcing .");
    system("cp -r $CYCLE_DIR/20* $workdir/cycledata/ && touch $workdir/cycledata/flag.copy");
}

#plot
@plots=("precp", "tiles", "evapor", "streamflow_TG", "streamflow_SZ", "streamflow_GL", "streamflow_D4", "timeseries");
for $plot (@plots) {
    print((/"plot: $plot"/))
    if($plot eq "precp") {
        
    
    




sub wait_hydro_run(){
    my ($dir_hydro_run, $expected_date, $max_wait"





