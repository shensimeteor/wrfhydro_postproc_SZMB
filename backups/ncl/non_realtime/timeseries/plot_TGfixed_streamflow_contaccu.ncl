load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
; fixed: plot contaccu streamflow, for all 6 nodes, and sum of inflow
; sishen, 20170822

begin
    ;input: file_pattern, optional (start_date10, end_date10)
    if(.not. isvar("file_pattern")) then
        print((/"input: file_Pattern (streamflow file pattern to ls)"/))
        print((/" optional: start_date10, end_date10, the range of X axis in plots"/))
        exit
    end if
    nodes_idx_list="17751,18024,18286,16975,15568,14986" ; 0..4, inflow, 5, outflow
    nodes_name_list="NorWst,North,NorEst,East,SouEst,South,SumIn" ; 6 nodes + 1 sumIn
    color_list="blue,green,red,cyan,orange,black,magenta" ; 6 nodes + 1 sumIn
    nodes_idx=tointeger(str_split(nodes_idx_list,","))
    nodes_names=str_split(nodes_name_list, ",")
    files=systemfunc("ls -1 "+file_pattern)
    nfile=dimsizes(files)
    if(.not. isvar("start_date10")) then
        start_date10=str_substr(basename(files(0)), 0, 9)
    end if
    if(.not. isvar("end_date10")) then
        end_date10=str_substr(basename(files(nfile-1)), 0, 9)
    end if
    colors=str_split(color_list, ",")
    nline=dimsizes(nodes_idx)+1
    ;read 2d, data2d(nfile_between_start_end, n_node+1, 1 for sum of inflow nodes)
    streamflow_data2d=read_nodes_streamflow(files, nodes_idx)
    streamflow_data2d(0,:) = 0
    str_dt=streamflow_data2d@str_dt
    accu_data2d = dim_cumsum_n_Wrap(streamflow_data2d, 1, 0) * 3600 / 1000
    data2dx=new((/nfile, nline/), "float")
    data2dx(:,0:nline-2) = accu_data2d
    data2dx(:,nline-1) = dim_sum_n(data2dx(:,0:nline-3),1)
    hour_start=date14_scalar_cd_inv_calendar(start_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    hour_end=date14_scalar_cd_inv_calendar(end_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    all_hours=date14_1darr_cd_inv_calendar(str_dt+"0000", "hours since 1970-01-01 00:00:00", 0)
    idx=ind(all_hours .le. hour_end .and. all_hours .ge. hour_start)
    data2d=(/data2dx(idx,:)/)
    copy_VarMeta(streamflow_data2d, data2d)

    ;plot TS
    wks=gsn_open_wks("png", "TG_streamflow_contaccu_allnodes_ts")
    res=True
    res@xyLineColors= colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "Nodes 3hr-Accumulated StreamFlow (10~S~3~N~ m~S~3~N~) "
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
;    res@vpYF=0.1
    res@vpWidthF = 0.7
    res@vpHeightF = 0.5
    plot=plot_ts_lines(wks, str_dt(idx), data2d, res)
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
    gsn_legend_ndc(wks,nline,nodes_names,0.87,0.75,lgres) 
    draw(plot)
    frame(wks)
    delete(wks)
end
