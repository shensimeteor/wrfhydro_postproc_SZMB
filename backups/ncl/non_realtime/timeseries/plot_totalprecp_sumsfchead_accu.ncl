load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
; plot: area_sum_precp_in_m3/s, area_sum_sfchead_in m3
; input: in_nodes_idx_list (=1,2,5,7,); out_nodes_idx_list; colors_inout_list
;        area_sum_precp_filelist; area_sum_precp_namelist; colors_area_list
;        streamfile_pattern, precpfile_pattern
; sishen, 20170823

begin
   
    all_input_vars=(/"area_sum_precp_filelist", "area_sum_precp_namelist", "colors_precp_list","precpfile_pattern",  \
                     "area_sum_sfchd_filelist", "area_sum_sfchd_namelist", "colors_sfchd_list","sfchdfile_pattern", \
                     "accu_hour_list"/)
    if(.not. all(isvar(all_input_vars))) then
        print((/"Error: need 9 input_var from cmd line arguments: "/))
        print((/"-- area_sum_precp_filelist: xyidx_inside_area_file_list_sperated_by_comma"/))
        print((/"-- area_sum_precp_namelist: area_name_list"/))
        print((/"-- colors_precp_list: colors for areas"/))
        print((/"-- precpfile_pattern: precp_input_file_pattern_to_ls"/))
        print((/"-- area_sum_sfchd_filelist: yxidx_inside_hires_area_file_list_sperated_by_comma"/))
        print((/"-- area_sum_sfchd_namelist .."/))
        print((/"-- colors_sfchd_list .."/))
        print((/"-- sfchdfile_pattern .."/))
        print((/"-- accu_hour_list .."/))
        print((/" optional: start_date10, end_date10 .."/))
    end if
    precp_area_idx_files=str_split(area_sum_precp_filelist, ",")
    precp_area_names=str_split(area_sum_precp_namelist,",")
    sfchd_area_idx_files=str_split(area_sum_sfchd_filelist, ",")
    sfchd_area_names=str_split(area_sum_sfchd_namelist,",")
    all_colors_list=colors_precp_list+","+colors_sfchd_list
    all_colors=str_split(all_colors_list, ",")
    accu_hours=tointeger(str_split(accu_hour_list, ","))
    nhour=dimsizes(accu_hours)

    precpfiles=systemfunc("ls -1 "+precpfile_pattern)
    sfchdfiles=systemfunc("ls -1 "+sfchdfile_pattern)
    nfile=dimsizes(precpfiles)
    if(.not. isvar("start_date10")) then
        start_date10=str_substr(basename(sfchdfiles(0)), 0, 9)
    end if
    if(.not. isvar("end_date10")) then
        end_date10=str_substr(basename(sfchdfiles(nfile-1)), 0, 9)
    end if
    if(dimsizes(sfchdfiles) .ne. dimsizes(precpfiles)) then
        print((/"Error: sfchdfiles & precpfiles should have same size"/))
        exit
    end if
    nline=dimsizes(all_colors)
    nline_precp=dimsizes(precp_area_names)
    nline_sfchd=dimsizes(sfchd_area_names)

    ;read 
    precp_data3d=read_area_sum_precp_accu(precpfiles, precp_area_idx_files, accu_hours, 1, 1)
    sfchd_data3d=read_area_sum_sfchead_accu(sfchdfiles, sfchd_area_idx_files, accu_hours, 100, 100)
    str_dt=sfchd_data3d@str_dt
    ;get date idx
    hour_start=date14_scalar_cd_inv_calendar(start_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    hour_end=date14_scalar_cd_inv_calendar(end_date10+"0000", "hours since 1970-01-01 00:00:00", 0)
    all_hours=date14_1darr_cd_inv_calendar(str_dt+"0000", "hours since 1970-01-01 00:00:00", 0)
    idx=ind(all_hours .le. hour_end .and. all_hours .ge. hour_start)
    nidx=dimsizes(idx)
    plot_data2d=new((/nfile, nline /), "float")
    copy_VarMeta(precp_data3d, plot_data2d)
    do i=0, nhour-1
        plot_data2d(:,0:nline_precp-1) = precp_data3d(:,:,i) 
        plot_data2d(:,nline_precp:nline-1)=sfchd_data3d(:,:,i)
        ;plot
        wks=gsn_open_wks("png", "Precp_and_SfcHead_Accu"+sprinti("%0.2i",accu_hours(i))+"h")
        res=True
        res@xyLineColors= all_colors
        res@xyLineThicknessF = 5.0
        res@xyDashPattern = 0
        res@tiMainString = ""+accu_hours(i)+"hr Accu. Precp & SfcHead Water (10~S~3~N~ m~S~3~N~)"
        res@gsnFrame=False
        res@gsnDraw=False
        res@vpXF=0.15
        plot=plot_ts_lines(wks, str_dt(idx), plot_data2d(idx,:), res)
        ;add legend
        lgres                    = True
        lgres@lgLineColors       = all_colors
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
        legend_lab(0: nline_precp-1) = "precp:"+precp_area_names
        legend_lab(nline_precp:nline-1) = "sfchd:"+sfchd_area_names
        gsn_legend_ndc(wks,nline,legend_lab,0.87,0.75,lgres)
        draw(plot)
        frame(wks)
        delete(wks)
    end do
end
