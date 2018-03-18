load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
load "ncl_future_func.ncl"
load "convert_and_copyout_forTS.ncl"
; to plot averaged sfchead on each of lonlats with a half_buffer local area
; one node one plot; 
; input: pt_lonlats_list (format: lon1,lat1;lon2,lat2;...), specify location of points
;        pt_names_list (format: name_pt1,name_pt2,..), specify short names (in png file name) of points
;        pt_titles_list (format: title_pt1,title_pt2,..), specify titles (appear in png figure) of points
;        half_buffer (e.g. 2, means 5*5=25), for averaging
;        file_pattern: to ls
;        accu_hour_list (=1,2,3,6)
;        color_list (=red,green,..)
; optional: *start_date10, *end_date10 (the plotting xcoord min/max)
;           *ymax (default 1000 mm) 
;           *copydir_list (for realtime)
;           *cycle_date10 (YYYYMMDDHH cycle)
;           *data_outfile_prefix (to save time-series data in ${data_outfile_prefix}_ptXX.csv)
; sishen, 20170822

begin
    all_input_vars=(/"pt_lonlats_list", "pt_names_list", "pt_titles_list", "half_buffer", "file_pattern", "accu_hour_list", "color_list"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 5 input_var from cmd line arguments: "/))
        print((/"-- pt_lonlats_list: separated by comma and semicolon, e.g. lon1,lat1;lon2,lat2"/))
        print((/"-- pt_names_list: separated by comma, e.g., SZSK,XLSK"/))
        print((/"-- pt_titles_list: separated by comma, e.g., ShenZhen SK,XiLi SK"/))
        print((/"-- half_buffer: a integer (>=0), to specify the area to average for each point, e.g. 2 means 5x5 averaging"/))
        print((/"-- file_pattern: input_file_pattern_to_ls"/))
        print((/"-- accu_hour_list: accumulated_hour_list_separaeted_by_comma"/))
        print((/"-- color_list: ncl_named_color_list_separated_by_comma"/))
        exit
    end if
    pt_lonlats=str_split(pt_lonlats_list, ";")
    npt=dimsizes(pt_lonlats)
    pt_lonlats_2d=new((/npt, 2/), "float")
    do i=0, npt-1
        pt_lonlats_2d(i,:) = tofloat(str_split(pt_lonlats(i), ","))
    end do
    if(half_buffer .lt. 0) then
        print((/"Error, half_buffer should be integer and >= 0"/))
        exit
    else
        box_size=2*half_buffer+1
        print((/"You select half_buffer = "+half_buffer+", that is "+box_size+"*"+box_size+" box averging"/))
    end if
    pt_names=str_split(pt_names_list, ",")
    pt_titles=str_split(pt_titles_list, ",")
    colors=str_split(color_list, ",")
    accu_hours=tointeger(str_split(accu_hour_list, ","))
    if(dimsizes(colors) .ne. dimsizes(accu_hours)) then
        print((/"Error, color_list and accu_hour_list size conflict"/))
        exit
    end if
    files=systemfunc("ls -1 "+file_pattern)
    nfile=dimsizes(files)
    if(nfile .le. 1) then
        print((/"nfile should at least 2"/))
        exit
    end if
    nline=dimsizes(accu_hours)
    if(.not. all(nline .eq.  (/dimsizes(colors)/)) ) then
        print((/"Error: colors & accu_hours  should be same size"/))
        exit
    end if
    if(.not. isvar("start_date10")) then
        start_date10=str_substr(basename(files(0)), 0, 9)
    end if
    if(.not. isvar("end_date10")) then
        end_date10=str_substr(basename(files(nfile-1)), 0, 9)
    end if
    if(.not. isvar("ymax")) then
        ymax=1000
    end if
   if(.not. isvar("copydir_list")) then
       copydirs=(/""/)
   else
       copydirs=str_split(copydir_list, ",")
    end if
    if(isvar("copydir_list") .and. .not. isvar("cycle_date10")) then
        print((/"Error, since you pass copydir_list, you should pass cycle_date10 as well"/))
        exit
    end if
    if(isvar("data_outfile_prefix")) then
        print((/"Log: you will write data to "+data_outfile_prefix +"*.csv"/))
    end if
    ;read 3d
    data3d=read_point_sfchead_diff(files, pt_lonlats_2d(:,0), pt_lonlats_2d(:,1), half_buffer, accu_hours)
    if(max(data3d) .gt. ymax) then
        print((/"Warning: max(data3d)="+sprintf("%f", max(data3d))+", exceed ymax"/))
    else
        print((/"max(data3d)="+sprintf("%f", max(data3d))/))
    end if
    ;plot TS
    do ipt=0, npt-1
        fig_name= "change_sfchead_ts_pt"+pt_names(ipt)
        wks=gsn_open_wks("png",fig_name)
        res=True
        res@xyLineColors= colors
        res@xyLineThicknessF = 5.0
        res@xyDashPattern = 0
        res@tiMainString = "Surface Head Change TimeSeries  (mm)"
        res@gsnLeftString= pt_titles(ipt) + sprintf("(%6.2f,",pt_lonlats_2d(ipt,0))+sprintf("%5.2f)",pt_lonlats_2d(ipt,1))
        res@gsnFrame=False
        res@gsnDraw=False
        res@vpXF=0.15
        res@trYMaxF = ymax
        res@trYMinF = 0
    ;    res@vpYF=0.1
        res@vpWidthF = 0.7
        res@vpHeightF = 0.5
        ; 
        hour_start=date14_scalar_cd_inv_calendar(start_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
        hour_end=date14_scalar_cd_inv_calendar(end_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
        all_hours=date14_1darr_cd_inv_calendar(data3d@str_dt+"0000", "hours since 1970-01-01 00:00:00", 0)
        idx=ind(all_hours .le. hour_end .and. all_hours .ge. hour_start)
        data2d=(/data3d(idx,ipt,:)/)
        copy_VarMeta(data3d, data2d)
        if(isvar("cycle_date10")) then ; to add a red point marker in X axis
            mkres=True
            mkres@gsMarkerColor = "thistle3"
            mkres@gsMarkerIndex = 16
            mkres@gsMarkerSizeF = 0.02
            plot=plot_ts_lines_withDateMarker(wks, data2d@str_dt(idx), data2d, res, cycle_date10, mkres)
        else
            plot=plot_ts_lines(wks, data2d@str_dt(idx), data2d, res)
        end if
        ;add legend
        lgres                    = True
        lgres@lgLineColors       = colors
        lgres@lgLineThicknessF   = 3.
        lgres@lgLabelFontHeightF = 0.15
        lgres@vpWidthF           = 0.12              
        lgres@vpHeightF          = 0.03*nline
        lgres@lgPerimOn          = True               
        zeros=new((/nline/), "float")
        zeros=0
        lgres@lgDashIndexes        = zeros
        lgres@lgPerimFillColor   = 0
        lgres@lgPerimFill        = 0
        legends_lables=""+accu_hours+" hr"
        gsn_legend_ndc(wks,nline,legends_lables,0.87,0.75,lgres) 
        draw(plot)
        frame(wks)
        delete(wks)
        convert_and_copyout_forTS(fig_name+".png", copydirs, cycle_date10)
        ;; write out data to csv file
        if(isvar("data_outfile_prefix")) then
            outfile=data_outfile_prefix+"_pt"+pt_names(ipt)+".csv"
            boxsize=2*half_buffer+1
            var_addlines=(/"surface head; "+pt_titles(ipt)+"; "+pt_lonlats(ipt)+"; average boxsize:"+boxsize /)
            var_titles="AcHr:"+accu_hours
            writeout_data_withSupplementLines(data2d@str_dt(idx), data2d, var_titles, outfile, var_addlines)
        end if
    end do
end
