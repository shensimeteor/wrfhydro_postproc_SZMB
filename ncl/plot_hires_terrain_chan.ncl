load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "gsn_add_shapefile_polylines_for_v600.ncl"
load "any2d_lonlat_to_ij.ncl"
load "smooth_convolution.ncl"

begin
; plot chan order (colored) overlaid on gray shaded hires terrain
; input:
;  srcfilename: e.g. ../cons/Fulldom_hires_netcdf_file.nc
;  chanfilename: e.g. 201706120000.CHRTOUT_DOMAIN1
;  optional: *lonlat_list=lon1,lon2,lat1,lat2, *dom_name (predefined: TG, SZ, etc)
;            *avg_filter_kernel_size
    
 if(.not. isvar("srcfilename") .or. (.not. isvar("chanfilename"))) then
     print((/"Error, must provide srcfilename(hires ter file); chanfilename"/))
     print((/"Optional: lonlat_list(lon1,lon2,lat1,lat2); "/))
     print((/"          dom_name (name of dom); "/))
     print((/"          avg_filter_kernel_size (the kernel size to filter terrain height "/))
     print((/"          nodeidx_file = file_path_of_node_idx_begin_with_0 .."/))
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
 if( isvar("nodeidx_file")) then
     nodeidx=asciiread(nodeidx_file, -1, "integer")
 end if

 ;begin plot ------------
 vars_to_plot=(/"TOPOGRAPHY"/)
 nvar=dimsizes(vars_to_plot)
 ff = addfile(srcfilename+".nc","r")
 got_h=0
 ;got i1,i2,j1,j2
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
     print((/i1,j1,i2,j2/))
     print((/lon2d(j1,i1), lat2d(j1,i1), lon2d(j2,i2), lat2d(j2,i2)/))
 else
     if(dom_name .eq. "D4") then
         i1=0
         i2=dims(1)-1
         j1=dims(0)-1
         j2=0
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
 order_colors=(/"blue", "cyan", "green", "yellow", "orangered", "red4"/) ; 1-6
 ;plot
 do ivar=0, nvar-1
     var2dx=ff->$vars_to_plot(ivar)$
     if(isvar("avg_filter_kernel_size")) then
         ;;do filter
         if(got_h .eq. 0) then
             h_matrix = get_conv2d_avg(hs, hs)
             got_h=1
         end if
         var2dz=conv2d_2darray(h_matrix, var2dx(0,:,:), 2)
         var2dx=(/var2dz/)
     end if
     var2d=var2dx(j1:j2, i1:i2)
     var2d@lon2d = lon2d(j1:j2, i1:i2)
     var2d@lat2d = lat2d(j1:j2, i1:i2)
     var2d@_FillValue=-9999
     print((/vars_to_plot(ivar)+ " max:"+max(var2d)+" min:"+min(var2d)/))
     varname=str_sub_str(vars_to_plot(ivar), " ", "_")
     pngfile=varname+"_"+dom_name
     wks = gsn_open_wks("png",pngfile)
;     gsn_define_colormap(wks, "MPL_terrain")
;     gsn_define_colormap(wks, "BlAqGrYeOrRe")
     gsn_define_colormap(wks, "gsdtol")

     res	= True
     res@gsnDraw = False
     res@gsnFrame = False
     res@pmTickMarkDisplayMode       = "Always"
     res@cnFillOn                    = True
     res@cnLinesOn                   = False
     res@cnLineLabelsOn              = False
     if(vars_to_plot(ivar) .eq. "TOPOGRAPHY") then
         if(dom_name .eq. "GL") then
             res@cnLevelSelectionMode="ExplicitLevels"
             res@cnLevels=fspan(30,510,17)
             res@cnFillColors=tointeger(fspan(32, 4, 18))
         else
            if(dom_name .eq. "TG") then
               res@cnLevelSelectionMode="ExplicitLevels"
               res@cnLevels=fspan(0,320,17)
               res@cnFillColors=tointeger(fspan(32, 4, 18))
            else
                if(dom_name .eq. "D4") then
                    res@cnLevels=fspan(0, 950, 20)
                    res@cnFillColors=tointeger(fspan(32, 4, 21))
                else
                    if(dom_name .eq. "SZ") then
                        res@cnLevels=fspan(0, 950, 20)
                        res@cnFillColors=tointeger(fspan(32, 4, 21))
                    else
                        print("Warn, dom_name not recoginized, use automatic levelselection for Terrain")
                    end if
                end if
            end if
        end if
     end if

     ;;
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
     res@mpOutlineOn = "False"
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
   
     map = gsn_csm_contour_map(wks,var2d, res)
     lnres             = True   
     lnres@gsLineColor     = "black" 
     lnres@gsLineThicknessF    = 1.5
     map_SZD = gsn_add_shapefile_polylines(wks,map,"./SZDistrictSurface.nc",lnres)
     ; add channel order
     gg=addfile(chanfilename, "r")
     if(isvar("nodeidx")) then
         lat    = gg->latitude(nodeidx)
         lon    = gg->longitude(nodeidx)
         stream = gg->streamflow(nodeidx)
         order  = gg->order(nodeidx)
     else
         lat    = gg->latitude
         lon    = gg->longitude
         order  = gg->order
     end if
     max_order=max(order)
     point=new(max_order, graphic)
     do i=1,max_order
         gsres=True
         gsres@gsMarkerIndex=16
         if(dom_name .eq. "D4" .or. dom_name .eq. "SZ") then
             gsres@gsMarkerThicknessF = 0.2
             gsres@gsMarkerSizeF  = 0.001
         else
             gsres@gsMarkerThicknessF=2
             gsres@gsMarkerSizeF = 0.007
         end if
         gsres@gsMarkerColor = order_colors(i-1)
         idx=ind(order .eq. i)
         point(i-1) =  gsn_add_polymarker(wks,map,lon(idx),lat(idx),gsres)
         delete(idx)
     end do
     ;add text & legends
     xleg=new((/6/), "float")
     xleg=0.84
     yleg=(/0.7,0.65,0.6,0.55,0.5,0.45/)
     xtxt=new((/6/), "float")
     xtxt=0.88
     ytxt=yleg
     txres=True
     txres@txFontHeightF = 0.012
     legres=True
     legres@gsMarkerSizeF = 0.01
     legres@gsMarkerIndex = 16
     do i=1,max_order
         label="order "+i
         legres@gsMarkerColor = order_colors(i-1)
         gsn_polymarker_ndc(wks, xleg(i-1), yleg(i-1), legres)
         gsn_text_ndc(wks, label, xtxt(i-1), ytxt(i-1), txres)
     end do 
     draw(map)
     frame(wks)
 end do
end

