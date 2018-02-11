load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "HYDRO_LIB.ncl"
;; plot rate of sum_precipiation (lake), sum_sfchd_accumulation (lake), sum_soilm_accumlation (lake)
begin
;    precpfile_pattern="*.LDASIN_DOMAIN1"
;    sfchdfile_pattern="*.RTOUT_DOMAIN1"
    if(.not. all(isvar((/"sfchdfile_pattern"/)))) then
        print((/"Error, you need to prepare, sfchdfile_pattern"/))
    end if
    sfchdfiles=systemfunc("ls "+sfchdfile_pattern)
    nfile=dimsizes(sfchdfiles)
    sfchd_area_idx_files=(/"hires_idx_inside_TG_lakearea.txt"/)
    ;read
    soilm_data3d=read_area_sum_soilm_conc(sfchdfiles, sfchd_area_idx_files); m3
    ;plot
    nlines=4
    plot_data2d=new((/nfile, nlines/), "float")
    plot_data2d(:,:) = soilm_data3d(:,0,:)
    labels=(/"SoilM_1", "SoilM_2", "SoilM_3", "SoilM_4"/)
    colors=(/"cyan", "deepskyblue", "royalblue", "blue"/)
    ; 
    wks=gsn_open_wks("png", "precp_soilm_conc")
    res=True
    res@xyLineColors= colors
    res@xyLineThicknessF = 5.0
    res@xyDashPattern = 0
    res@tiMainString = "SoilM Conc. (m~S~3~N~ / m~S~3~N~)"
    res@gsnFrame=False
    res@gsnDraw=False
    res@vpXF=0.15
    plot=plot_ts_lines(wks, soilm_data3d@str_dt, plot_data2d, res)
    lgres                    = True
    lgres@lgLineColors       = colors
    lgres@lgLineThicknessF   = 3.
    lgres@lgLabelFontHeightF = 0.15
    lgres@vpWidthF           = 0.12              
    lgres@vpHeightF          = 0.04 * nlines
    lgres@lgPerimOn          = True               
    zeros=new((/nlines/), "float")
    zeros=0
    lgres@lgDashIndexes        = zeros
    lgres@lgPerimFillColor   = 0
    lgres@lgPerimFill        = 0
    gsn_legend_ndc(wks,nlines,labels,0.8,0.75,lgres)
    draw(plot)
    frame(wks)
    delete(wks)
end
