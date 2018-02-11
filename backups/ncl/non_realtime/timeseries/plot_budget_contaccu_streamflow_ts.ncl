load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
; upper plot: to plot continuly accumulated streamflow for inflow & outflow as TimeSeries 
; lower plot: to plot lakes' continuly accumulated streamflow budget (instantaneous) = inflow - outflow
; input: in_nodes_idx_list (=1,2,5,7,); out_nodes_idx_list; file_pattern_in
; sishen, 20170823

undef("basename"); remove dir parts of a path
function basename(fileordir)
local base
begin
    base=systemfunc("basename "+fileordir)
    return(base)
end


undef("read_stats_file")
;ncol is number of line to draw (actual n_col = ncol+1)
function read_stats_file(filename:string, ncol:integer)
local data2d, data2dx
begin
    data2dx=readAsciiTable(filename, ncol+1, "double", 1)
    data2d=tofloat(data2dx(:,1:))
    data2d@str_dt=tostring(tointeger(data2dx(:,0)))
    data2d@missing_value=-999.0
    data2d@_FillValue=-999.0
    return(data2d)
end


undef("read_nodes_streamflow")
;return data2d, data2d@str_dt (in format of date10)
function read_nodes_streamflow(files: string, nodes: numeric)
local data2d,nfile,nnode,ifile,str_dt10,chartemp,fbasename,f
begin   
    nfile=dimsizes(files)
    nnode=dimsizes(nodes)
    data2d=new((/nfile, nnode/), "float")
    str_dt10=new((/nfile/), "string")
    do ifile=0,nfile-1
        f=addfile(files(ifile)+".nc", "r")
        data2d(ifile,:)=f->streamflow(nodes)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
    end do
    data2d@str_dt=str_dt10
    return(data2d)
end

undef("read_nodes_contaccu_streamflow")
;return data2dx, data2dx@str_dt (in format of date10) (units: 10^3 m^3)
function read_nodes_contaccu_streamflow(files: string, nodes: numeric)
local data2dx,data2d,nfile,nnode,ifile,str_dt10,chartemp,fbasename,f
begin   
    nfile=dimsizes(files)
    nnode=dimsizes(nodes)
    data2d=new((/nfile, nnode/), "float")
    str_dt10=new((/nfile/), "string")
    do ifile=0,nfile-1
        f=addfile(files(ifile)+".nc", "r")
        data2d(ifile,:)=f->streamflow(nodes)
        fbasename=basename(files(ifile))
        chartemp=stringtochar(fbasename)
        str_dt10(ifile)=chartostring(chartemp(0:9))
    end do
    data2d(0,:) = 0
    data2dx=dim_cumsum_n_Wrap(data2d, 1, 0) * 3600 / 1000
    data2dx@str_dt=str_dt10
    return(data2dx)
end


    

undef("plot_ts_lines")
function plot_ts_lines(wks:graphic, str_dt:string, stats2d:numeric, res:logical)
local char_dt, x_year, x_month, x_day, x_hour, minute, second, dt_unit, time_to_plot, day_to_plot, \
    labels_to_plot, idx_label
begin
    char_dt=stringtochar(str_dt)
    ;define input x's datetime
    x_year=chartostring(char_dt(:,0:3))
    x_month=chartostring(char_dt(:,4:5))
    x_day=chartostring(char_dt(:,6:7))
    x_hour=chartostring(char_dt(:,8:9))
    minute=x_hour
    minute=0
    second=minute
    dt_unit="hours since "+x_year(0)+"-"+x_month(0)+"-"+x_day(0)+" "+x_hour(0)+":00:00"
    xtime=cd_inv_calendar(tointeger(x_year), tointeger(x_month), tointeger(x_day), tointeger(x_hour), tointeger(minute), tointeger(second), dt_unit, 0); 
    ;define xcoord's datetime
    all_dt_start=tointeger(min(xtime))
    all_dt_end=tointeger(max(xtime))
    all_date_coord = ispan(all_dt_start, all_dt_end, 1)
    all_date_coord@units = dt_unit
    all_date_string      = ut_calendar(all_date_coord,-3)
    all_dates_char  =  stringtochar(sprinti("%0.10i", all_date_string))
    all_year        =  chartostring(all_dates_char(:,0:3))
    all_month       =  chartostring(all_dates_char(:,4:5))
    all_day         =  chartostring(all_dates_char(:,6:7))
    all_hour        =  chartostring(all_dates_char(:,8:9))
    day_to_plot= where(all_hour .eq. "00" .OR. all_hour .eq. "12", all_month+"/"+all_day,"")
    labels_to_plot = all_hour+":00~C~"+day_to_plot
    idx_label=ind(all_hour .eq. "00" .or. all_hour .eq. "06" .or. all_hour .eq. "12" .or. all_hour .eq. "18")

    res@trXMinF=min(xtime)
    res@trXMaxF=max(xtime)
    res@tmLabelAutoStride           = True
    res@tmXMajorGrid                = True
    res@tmXMajorGridThicknessF      = 0.9
    res@tmXMajorGridLineDashPattern = 2
    res@tmXMajorGridLineColor       = "gray80"
    res@tmXBMode                    = "Explicit"
    res@tmXBValues                  = all_date_coord(idx_label)
    res@tmXBLabels                  = labels_to_plot(idx_label)
    res@tmXBMinorValues             = all_date_coord
    res@tmXBLabelFontHeightF   =    0.015
    res@tmYLLabelFontHeightF   =    0.015
    res@tmYROn                      = True
    res@tmYMajorGrid                = True    
    res@tmYMajorGridThicknessF      = 0.9    
    res@tmYMajorGridLineDashPattern = 2    
    res@tmYMajorGridLineColor = "gray80"
    plot = gsn_csm_xy (wks,xtime,transpose(stats2d),res)
    return(plot)
end

begin
   
    all_input_vars=(/"in_nodes_idx_list", "out_nodes_idx_list", "file_pattern" /)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 3 input_var from cmd line arguments: "/))
        print((/"-- in_nodes_idx_list: inflow_nodes_index_list_separated_by_comma, begin with 0"/))
        print((/"-- out_nodes_idx_list: outflow_nodes_index_list_separated_by_comma .."/))
        print((/"-- file_pattern: input_file_pattern_to_ls"/))
        exit
    end if
    in_nodes_idx=tointeger(str_split(in_nodes_idx_list,","))
    out_nodes_idx=tointeger(str_split(out_nodes_idx_list, ","))
    n_in=dimsizes(in_nodes_idx)
    n_out=dimsizes(out_nodes_idx)
    files=systemfunc("ls -1 "+file_pattern)
    nline=2
    ;read 2d
    n_all=n_in+n_out
    all_nodes_idx=new((/n_all/), "integer")
    all_nodes_idx(0:n_in-1) = in_nodes_idx
    all_nodes_idx(n_in:n_all-1)= out_nodes_idx
    all_data2d=read_nodes_contaccu_streamflow(files, all_nodes_idx)
    in_sum=dim_sum_n_Wrap(all_data2d(:, 0:n_in-1), 1)
    out_sum=dim_sum_n_Wrap(all_data2d(:, n_in:n_all-1), 1)
    plot_data2d=transpose((/in_sum, out_sum/)) ; in/ out flow
    plot_budget = onedtond(in_sum - out_sum, (/dimsizes(in_sum),1/))
    str_dt=all_data2d@str_dt
    ;plot 
    wks=gsn_open_wks("png", "inoutbudget_contaccu_streamflow")
    ;plot in/out two lines
    res=True
    res@xyLineColors= (/"red", "blue"/)
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "In/Out Cont. Accum. StreamFlow (10~S~3~N~ m~S~3~N~) "
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
;    res@vpYF=0.1
    res@vpWidthF = 0.7
    res@vpHeightF = 0.35
    plot=plot_ts_lines(wks, str_dt, plot_data2d, res)
    ;plot_budget
    res2=True
    res2@xyLineColors = (/"black"/)
    res2@xyLineThicknessF = 5.0
    res2@tiMainString = "Budget (In - Out) Cont. Accum. Streamflow (10~S~3~N~ m~S~3~N~) "
    res2@gsnFrame=False
    res2@gsnDraw=False
    res2@vpXF=0.15
    res2@vpWidthF = 0.7
    res2@vpHeightF = 0.35
    plot2=plot_ts_lines(wks, str_dt, plot_budget, res2)
    ;add legend
    lgres                    = True
    lgres@lgLineColors       = (/"red","blue","black"/)
    lgres@lgLineThicknessF   = 3.
    lgres@lgLabelFontHeightF = 0.15
    lgres@vpWidthF           = 0.12              
    lgres@vpHeightF          = 0.1
    lgres@lgPerimOn          = True               
    zeros=new((/3/), "float")
    zeros=0
    lgres@lgDashIndexes        = zeros
    lgres@lgPerimFillColor   = 0
    lgres@lgPerimFill        = 0
    gsn_legend_ndc(wks,3,(/"inflow","outflow","budget"/),0.87,0.75,lgres)
    ;panel
    resP=True
    resP@gsnMaximize=True
;    resP@gsnPanelDebug  = True
    gsn_panel(wks, (/plot, plot2/), (/2,1/), resP)
    delete(wks)
end
