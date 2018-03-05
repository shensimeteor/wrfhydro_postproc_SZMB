load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "gsn_add_shapefile_polylines_for_v600.ncl"
load "any2d_lonlat_to_ij.ncl"
load "smooth_convolution.ncl"
load "ncl_future_func.ncl"
load "convert_and_copyout.ncl"

; run with version > 6.2.0 (ncl)

undef("read_ascii_lonlat")
;return lonlat(:,2), first column is lon, last column is lat
function read_ascii_lonlat(asciifile)
local data1d, nrow, lonlatx
begin   
    data1d=asciiread(asciifile, -1, "float")
    nrow=dimsizes(data1d)/2
    lonlatx=onedtond(data1d, (/nrow,2/))
    return(lonlatx)
end


undef("add_border_marker_line_TG")
function add_border_marker_line_TG(wks, plot)
local file_channel, file_basin_border, file_lake_border, plots, lonlat_channode, lonlat_basinborder, lonlat_lakeborder, res1, res2
begin
    file_channel="TG_channode_lonlat.txt"
    file_basin_border="TG_basinborder_lonlat.txt"
    file_lake_border="TG_lakeborder_lonlat.txt"
    plots=new((/3/), "graphic")
    ;channel
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plots(0)=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    ;border
    lonlat_basinborder=read_ascii_lonlat(file_basin_border)
    lonlat_lakeborder=read_ascii_lonlat(file_lake_border)
    res2=True
    res2@gsLineColor="black"
    res2@gsLineDashPattern = 1
    res2@gsLineThicknessF = 1.0
    plots(1)=gsn_add_polyline(wks, plot, lonlat_basinborder(:,0), lonlat_basinborder(:,1), res2)
    res2@gsLineDashPattern = 2
    plots(2)=gsn_add_polyline(wks, plot, lonlat_lakeborder(:,0), lonlat_lakeborder(:,1), res2)
    return(plots)
end

undef("add_node_marker_GL")
function add_node_marker_GL(wks, plot)
local file_channel, lonlat_channode, res1, plotx
begin

    file_channel="GL_channode_lonlat.txt"
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plotx=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    return(plotx)

end

undef("add_node_marker_TG")
function add_node_marker_TG(wks, plot)
local file_channel, lonlat_channode, res1, plotx
begin
    file_channel="TG_channode_lonlat.txt"
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plotx=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    return(plotx)
end

undef("add_node_marker")
function add_node_marker(wks, plot, dom_name)
local file_channel, lonlat_channode, res1, plotx, file_exist
begin
    file_channel=dom_name+"_channode_lonlat.txt"
    file_exist=tointeger(systemfunc("ls "+file_channel+" >& /dev/null && echo 1 || echo 0"))
    if(file_exist .eq. 0) then
        print((/"Warn: "+file_channel+" not exit, skip ploting node markers"/))
        return(0)
    end if
    lonlat_channode=read_ascii_lonlat(file_channel)
    res1=True
    res1@gsMarkerIndex=16
    res1@gsMarkerColor="black"
    res1@gsMarkerSizeF=0.002
    plotx=gsn_add_polymarker(wks, plot, lonlat_channode(:,0), lonlat_channode(:,1), res1)
    return(plotx)
end

begin

; input:
; argument: srcfilename: should be YYYYMMDDHHmm.LDASIN_DOMAIN1 (input file)
; optional:
;    lonlat_list=lon1,lon2,lat1,lat2 (define the subdomain to plot, default is whole domain)
;    dom_name (default is D4, other case: SZ--with predefined lonlat_list; TG; GL)
;    add_chan_border (default is "", other case: TGall, TG, GL, ...))
;      TGall: need TG_channode_lonlat.txt, TG_lakeborder_lonlat.txt TG_basinborder_lonlat.txt. plot channel-ndoes+border makers
;      XX: need XX_channode_lonlat.txt. plot channel nodes markers (XX can be any dom, e.g. TG,GL,BAB..), only plot channel-nodes
;    avg_filter_kernel_size (default is no filter, otherwise, give the size of conv.matrix--odd number; to smooth tile field)
;    copydir_list: for realtime run, a list separated by ',' containing dest-dir to cp pngs

 if(.not. isvar("srcfilename")) then
     print("Error, must provide srcfilename")
     print("Optional, lonlat_list(lon1,lon2,lat1,lat2); dom_name; avg_filter_kernel_size; add_chan_border; copydir_list ")
     exit
 end if
 if(.not. isvar("dom_name")) then
     dom_name="D4"
 end if
 if(isvar("avg_filter_kernel_size")) then
     hs=avg_filter_kernel_size
     if(mod(hs, 2) .eq. 0) then
         print((/"avg_filter_kernel_size must be odd, no even"/))
         exit
     end if
 end if
 if(.not. isvar("copydir_list")) then
     copydirs=(/""/)
 else
     copydirs=str_split(copydir_list, ",")
 end if
 
 ;vars_to_plot=(/"QSTRMVOLRT", "SFCHEADSUBRT", "QBDRYRT","ZWATTABLRT","SOIL_M 1", "SOIL_M 2", "SOIL_M 3", "SOIL_M 4", "soil_m_total"/)
 ;vars_to_plot=(/"SFCHEADSUBRT","soil_m_total","ZWATTABLRT", "SOIL_M 1", "SOIL_M 2", "SOIL_M 3", "SOIL_M 4"/)
 vars_to_plot=(/"SFCHEADSUBRT","SoilMTotal","SOIL_M 1"/) 
; soil_m_total: kg/m^2
 nvar=dimsizes(vars_to_plot)
; ===== one at a time =====
 fs = systemfunc("ls -1 "+srcfilename)
 num_fs = dimsizes(fs)
 gotij=0
 got_h=0
 do ifile = 0, num_fs-1, 1
    strs = str_split(fs(ifile),".")
    date_str = strs(0)
    dtime_map = (/4,2,2,2,2/)
    date_vec = str_split_by_length(date_str,dtime_map)
    ymdh = date_vec(0)+date_vec(1)+date_vec(2)+date_vec(3)
    print("For file "+fs(ifile)+" ymdh is "+ymdh)
    ff = addfile(fs(ifile)+".nc","r")
    ;got i1,i2,j1,j2
    if(gotij .eq. 0) then
        lon2d=ff->LONGITUDE
        lat2d=ff->LATITUDE
        dims=dimsizes(lon2d)
        if(isvar("lonlat_list")) then
            lonlats=tofloat(str_split(lonlat_list, ","))
            lon1=lonlats(0)
            lon2=lonlats(1)
            lat1=lonlats(2)
            lat2=lonlats(3)
            ij1=any2d_lonlat_to_ij(lon2d, lat2d, lon1, lat1)
            i1=ij1(1)
            j1=ij1(0)
            ij2=any2d_lonlat_to_ij(lon2d, lat2d, lon2, lat2)
            i2=ij2(1)
            j2=ij2(0)
            ;print((/i1,j1,i2,j2/))
            ;print((/lon2d(j1,i1), lat2d(j1,i1), lon2d(j2,i2), lat2d(j2,i2)/))
        else
            if(dom_name .eq. "D4") then
                i1=0
                i2=dims(1)-1
                j1=0
                j2=dims(0)-1
            else 
                if(dom_name .eq. "SZ") then
                  ; new 111*111 hires domain
                    i1=277
                    i2=1149
                    j1=416
                    j2=962
                  ; old 100*100 hires domain
                  ; i1=388
                  ; i2=1357
                  ; j1=793
                  ; j2=186
                 else
                    print("only D4/SZ dom_name have predefined lonlat_list, please define lonlat_list in cmd-arg \n")
                    exit
                 end if
            end if
            ;other predefined dom_name, to be defined
        end if
        print((/"domain: i1="+i1+", i2="+i2+", j1="+j1+", j2="+j2/))
        gotij=1
    end if
    ;plot
    do ivar=0, nvar-1
        ;print((/"start"/))
        if(vars_to_plot(ivar) .eq. "SoilMTotal") then
            var2dx=ff->$"SOIL_M 1"$ * 0.2 + ff->$"SOIL_M 2"$ * 0.4  + \
                   ff->$"SOIL_M 3"$ * 0.8 + ff->$"SOIL_M 4"$ * 0.6
            var2dx=var2dx
            var2dx@units="m3/m2"
            var2dx@long_name="soil total moist."
        else
            if(isfilevar(ff, vars_to_plot(ivar))) then
                var2dx=ff->$vars_to_plot(ivar)$
            else
                if(isfilevar(ff, str_lower(vars_to_plot(ivar)))) then
                    var2dx=ff->$str_lower(vars_to_plot(ivar))$
                else
                    print((/"Error, "+vars_to_plot(ivar)+" doesn't exist in "+fs(ifile)/))
                    exit
                end if
            end if
        end if
        ;if SOIL_M N (N=1..4)
        titles=str_split(vars_to_plot(ivar), " ")
        if(titles(0) .eq. "SOIL_M" .and. dimsizes(titles) .eq. 2) then
            var2dx@units="m3/m3"
            var2dx@long_name="soil moist. lev"+titles(1)
        end if
        delete(titles)
        if(isvar("avg_filter_kernel_size")) then
            ;;do filter
            if(got_h .eq. 0) then
                h_matrix = get_conv2d_avg(hs, hs)
                got_h=1
            end if
            var2dz=conv2d_2darray(h_matrix, var2dx(0,:,:), 2)
            ;printVarSummary(var2dx)
            ;printVarSummary(var2dz)
            var2dx=(/var2dz/)
        end if
        var2d=var2dx(0, j1:j2, i1:i2)
        var2d@lon2d = lon2d(j1:j2, i1:i2)
        var2d@lat2d = lat2d(j1:j2, i1:i2)
        ;print((/"after read var"/))
        varname=str_sub_str(str_sub_str(vars_to_plot(ivar), " ", ""), "_", "")
        pngfile=varname+"_"+dom_name+"_valid_at_"+ymdh
        wks = gsn_open_wks("png",pngfile)

        res	= True
        res@gsnDraw = False
        res@gsnFrame = False
        res@pmTickMarkDisplayMode       = "Always"
        res@cnFillOn                    = True
        res@cnFillMode = "RasterFill"
        res@cnLinesOn                   = False
        res@cnLineLabelsOn              = False
        res@cnConstFLabelOn  = False
        res@cnConstFEnableFill =True
        ;;
        res@cnLevelSelectionMode="AutomaticLevels"
        if(vars_to_plot(ivar) .eq. "SFCHEADSUBRT") then
            res@cnLevelSelectionMode = "ExplicitLevels"
            gsn_define_colormap(wks, "prcp_1")
            res@cnLevels = (/20, 50, 100, 150, 200, 500, 2000, 3000/)
            res@cnFillColors = (/0, 9, 10, 12, 13, 15, 16, 5, 1/)
        else
            gsn_define_colormap(wks, "precip2_17lev")
        end if
        if(vars_to_plot(ivar) .eq. "SoilMTotal") then
            res@cnLevelSelectionMode = "ExplicitLevels"
            res@cnLevels = (/0.4,0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95/)
            res@cnFillColors = (/2, 4, 5, 6, 7, 9, 10, 13, 14, 15, 16, 17, 18/)
        end if
        if(vars_to_plot(ivar) .eq. "ZWATTABLRT") then
            res@cnLevelSelectionMode = "ExplicitLevels"
            res@cnLevels = (/0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8/)
            res@cnFillColors = (/2, 6, 7, 9, 10, 13, 14, 15, 17, 19/)
        end if
        if(any(vars_to_plot(ivar) .eq. (/"SOIL_M 1", "SOIL_M 2", "SOIL_M 3", "SOIL_M 4"/))) then
            res@cnLevelSelectionMode = "ExplicitLevels"
;            res@cnLevels=fspan(0.31, 0.47, 17)
;            res@cnFillColors=ispan(2,19,1)
            res@cnLevels = fspan(0.0,0.5,11)
            res@cnFillColors= tointeger(fspan(2,18,12))
        end if
        res@mpProjection                = "LambertConformal"
        res@mpLambertParallel1F         = min(lat2d(j1:j2, i1:i2))
        res@mpLambertParallel2F         = max(lat2d(j1:j2, i1:i2))
        res@mpLambertMeridianF          = avg(lon2d(j1:j2, i1:i2))
        res@mpLimitMode                 = "Corners"
        res@mpLeftCornerLatF            = lat2d(j1,i1)
        res@mpLeftCornerLonF            = lon2d(j1,i1)
        res@mpRightCornerLatF           = lat2d(j2,i2)
        res@mpRightCornerLonF           = lon2d(j2,i2)
        res@mpFillOn                    = False
        res@mpOceanFillColor            = 5
        res@mpLandFillColor             = "transparent"
        res@mpFillDrawOrder             = "PreDraw"
        if(dom_name .eq. "D4" .or. dom_name .eq. "SZ") then
            res@mpOutlineOn = "True"
        else
            res@mpOutlineOn = "False"
        end if
        res@mpOutlineBoundarySets       = "National"
        res@mpOutlineDrawOrder  = "PostDraw"
        res@mpDataBaseVersion     = "HighRes"          ; Default is LowRes
        res@mpGeophysicalLineThicknessF	= 1
        res@mpGeophysicalLineColor = "gray20"
        res@mpGridLineDashPattern  = 2
        res@pmTickMarkDisplayMode  = "Always"
        res@tmYROn                 = False
        res@tmXTOn                 = False
      ; res@tiMainString           = "streamflow 10**2 m**3/s"
        res@tiMainString           = vars_to_plot(ivar)
        res@tiMainFontHeightF      = 0.020              ; smaller title
        res@gsnAddCyclic           = False
        res@tfDoNDCOverlay = True
        res@lbLabelBarOn   = True
        res@lbTitlePosition = "Bottom"
        res@lbPerimOn               = False
        res@lbOrientation           = "Horizontal"
        res@lbBoxLinesOn            = True
        res@lbBoxLineThicknessF     = 0.6
        res@lbTitleFontHeightF      = 0.016
        res@pmLabelBarWidthF        = 0.70
        res@pmLabelBarHeightF       = 0.1
      ;  res@lbLabelAutoStride    = True
        res@lbLabelStride = 1
        res@lbLabelFontHeightF      = 0.012
      ; drawNDCGrid(wks)
      
      ; map = gsn_csm_contour_map(wks,hgt_plot,res)
       ;print((/"before contour"/))
        map = gsn_csm_contour_map(wks,var2d, res)
        lnres             = True   
        lnres@gsLineColor     = "black" 
        lnres@gsLineThicknessF    = 1.0
        ; print((/"before polylines"/))
        map_SZD = gsn_add_shapefile_polylines(wks,map,"./SZDistrictSurface.nc",lnres)
        if(isvar("add_chan_border")) then
           if(add_chan_border .eq. "TGall") then
              plots=add_border_marker_line_TG(wks, map)
           else
              plots=add_node_marker(wks, map, add_chan_border)
           end if
        end if
        ;print((/"before draw frame"/))
        draw(map)
        frame(wks)
        ;print((/"finish"/))
        delete(res@cnLevels)
        delete(res@cnFillColors)
        delete(wks)
        delete(var2d)
        delete(var2dx)
        convert_and_copyout(pngfile+ ".png", copydirs)
    end do
 end do

end

