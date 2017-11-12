load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
load "ncl_future_func.ncl"
load "convert_and_copyout_forTS.ncl"
; to plot accumulated streamflow on specified node
; one node one plot; multiplines represent multi-accu-hours
; input: nodes_idx_list (starting with 0), accu_hour_list (=1,2,3,6)
;        color_list (=red,green,..), file_pattern (to ls)
; optional: *start_date10, *end_date10 (the plotting xcoord min/max)
;           *nodes_name_list (used to name png/title/etc., instead of nodeidx)
;           *ymax (default 200) 
;           *copydir_list (for realtime)
;           *cycle_date10 (YYYYMMDDHH cycle)
;           *data_outfile_prefix (to save time-series data in ${data_outfile_prefix}_nodeXX.csv)
; sishen, 20170822

begin
   
    all_input_vars=(/"nodes_idx_list", "accu_hour_list", "color_list", "file_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 4 input_var from cmd line arguments: "/))
        print((/"-- nodes_idx_list: index_list_separated_by_comma, begin with 0"/))
        print((/"-- accu_hour_list: accumulated_hour_list_separaeted_by_comma"/))
        print((/"-- color_list: ncl_named_color_list_separated_by_comma"/))
        print((/"-- file_pattern: input_file_pattern_to_ls"/))
        exit
    end if
    nodes_idx=tointeger(str_split(nodes_idx_list,","))
    accu_hours=tointeger(str_split(accu_hour_list, ","))
    nnode=dimsizes(nodes_idx)
    colors=str_split(color_list, ",")
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
    if(.not. isvar("nodes_name_list")) then
        nodes_name_list=nodes_idx_list
    end if
    if(.not. isvar("ymax")) then
        ymax=1000
    end if
    nodes_names=str_split(nodes_name_list, ",")
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
        exit
    end if
    ;read 3d
    data3d=read_accu_streamflow(files, nodes_idx, accu_hours)
    if(max(data3d) .gt. ymax) then
        print((/"Warning: max(data3d)="+sprintf("%f", max(data3d))+", exceed ymax"/))
    else
        print((/"max(data3d)="+sprintf("%f", max(data3d))/))
    end if
    ;plot TS
    do inode=0, nnode-1
        fig_name= "accu_streamflow_ts_node"+nodes_names(inode)
        wks=gsn_open_wks("png",fig_name)
        res=True
        res@xyLineColors= colors
        res@xyLineThicknessF = 5.0
        res@xyDashPattern = 0
        res@tiMainString = "Accumulated StreamFlow TimeSeries  (10~S~3~N~ m~S~3~N~)"
        res@gsnLeftString= "node:"+nodes_names(inode)+sprinti("(%0.5i)", nodes_idx(inode))
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
        data2d=(/data3d(idx,inode,:)/)
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
            outfile=data_outfile_prefix+"_node"+nodes_names(inode)+".csv"
            var_titles="AcHr:"+accu_hours
            writeout_data(data2d@str_dt(idx), data2d, var_titles, outfile)
        end if
    end do
end
