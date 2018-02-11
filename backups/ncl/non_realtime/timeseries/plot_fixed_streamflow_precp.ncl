load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"

begin
    all_input_vars=(/"precpfile_pattern", "streamfile_pattern"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"input: precpfile_pattern, streamfile_pattern"/))
        print((/" optional: start_date10, end_date10"/))
        exit
    end if
    streamfiles=systemfunc("ls -1 "+streamfile_pattern)
    precpfiles=systemfunc("ls -1 "+precpfile_pattern)
    nfile=dimsizes(precpfiles)
    if(dimsizes(streamfiles) .ne. dimsizes(precpfiles)) then
        print((/"Error: streamfiles & precpfiles should have same size"/))
        exit
    end if
    if(.not. isvar("start_date10")) then
        start_date10=str_substr(basename(streamfiles(0)), 0, 9)
    end if
    if(.not. isvar("end_date10")) then
        end_date10=str_substr(basename(streamfiles(nfile-1)), 0, 9)
    end if
    ;configuration
    hr_accu=3
    ; for streamflow nodes
    in_nodes_idx_list="17751,18024,18286,16975,15568"
    in_nodes_idx=tointeger(str_split(in_nodes_idx_list,","))
    out_nodes_idx=(/14986/)
    n_in=dimsizes(in_nodes_idx)
    n_out=dimsizes(out_nodes_idx)
    n_all=n_in+n_out
    all_nodes_idx=new((/n_all/), "integer")
    all_nodes_idx(0:n_in-1) = in_nodes_idx
    all_nodes_idx(n_in:n_all-1)= out_nodes_idx
    ; for precp idx file
    area_idx_files=(/"idx_inside_TG_lakearea.txt", "idx_inside_TG_newbasin.txt"/)
    area_names=(/"Resrv", "Basin"/)
    n_area=dimsizes(area_idx_files)
    ; for colors
    colors=(/"red", "blue", "green", "black"/)
    ;read streamflow
    streamflow_data3d=read_accu_streamflow(streamfiles, all_nodes_idx, (/hr_accu/))
    ;read precp
    areaprecp_data3d=read_area_sum_precp_accu(precpfiles, area_idx_files, (/hr_accu/), 1, 1)
    str_dt10x=areaprecp_data3d@str_dt
    ;combine plot_data2d
    plot_data2dx=new((/nfile, 2+n_area/), "float")
    plot_data2dx(:,0)=dim_sum_n(streamflow_data3d(:, 0:n_in-1,0),1) ; sum_in
    plot_data2dx(:,1)=dim_sum_n(streamflow_data3d(:, n_in:n_all-1,0),1); sum_out
    plot_data2dx(:,2:n_area+1) = areaprecp_data3d(:, :, 0); area precp
    ;get time idx
    hour_start=date14_scalar_cd_inv_calendar(start_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    hour_end=date14_scalar_cd_inv_calendar(end_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    all_hours=date14_1darr_cd_inv_calendar(str_dt10x+"0000", "hours since 1970-01-01 00:00:00", 0)
    idx=ind(all_hours .le. hour_end .and. all_hours .ge. hour_start)
    plot_data2d=(/plot_data2dx(idx,:)/)
    copy_VarMeta(areaprecp_data3d, plot_data2d)
    str_dt=str_dt10x(idx)
    nline=2+n_area

    ;plot 
    wks=gsn_open_wks("png", "chaninout_totalprecp_3h")
    ;plot in/out two lines
    res=True
    res@xyLineColors= colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "3hr Accu. ChanFlow + PrecpWater (10~S~3~N~ m~S~3~N~)"
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
;    res@vpYF=0.1
;    res@vpWidthF = 0.7
;    res@vpHeightF = 0.35
    plot=plot_ts_lines(wks, str_dt, plot_data2d, res)
    ;add legend
    lgres                    = True
    lgres@lgLineColors       = colors
    lgres@lgLineThicknessF   = 3.
    lgres@lgLabelFontHeightF = 0.15
    lgres@vpWidthF           = 0.12              
    lgres@vpHeightF          = 0.04 * nline
    lgres@lgPerimOn          = True               
    zeros=new((/nline/), "float")
    zeros=0
    lgres@lgDashIndexes        = zeros
    lgres@lgPerimFillColor   = 0
    lgres@lgPerimFill        = 0
    legend_lab=new((/nline/), "string")
    legend_lab(0)="inflow"
    legend_lab(1)="outflow"
    legend_lab(2:nline-1) = area_names
    gsn_legend_ndc(wks,nline,legend_lab,0.87,0.75,lgres)
    draw(plot)
    frame(wks)
    ;panel
;    resP=True
;    resP@gsnMaximize=True
;    resP@gsnPanelDebug  = True
;    gsn_panel(wks, (/plot, plot2/), (/2,1/), resP)
    delete(wks)

end
