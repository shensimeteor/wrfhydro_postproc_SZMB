undef("gsn_add_shapefile_polylines")
function gsn_add_shapefile_polylines(wks,plot:graphic,fname:string,lnres)
	local f, geomDims, numFeatures, lnres2
	begin
	;---Open the shapefile
	  f = addfile(fname,"r")

	  ;---Error checking
	    if(ismissing(f)) then
	        print("Error: gsn_add_shapefile_polylines: Can't open shapefile '" + \
				           fname + "'")
		    print("       No shapefile information will be added.")
		        return(new(1,graphic))
	  end if

	  ;---We can't use this routine to plot point data
	    if(.not.any(f@geometry_type.eq.(/"polygon","polyline"/))) then
	        print("Error: gsn_add_shapefile_polylines: geometry_type attribute must be 'polygon' or 'polyline'")
		    print("       No shapefile information will be added.")
		        return(new(1,graphic))
	  end if

	    if(lnres) then
	        lnres2 = lnres      ; Make a copy so that we don't keep gsSegments
		  else
		      lnres2 = True
		        end if

			;---Read data off the shapefile
			  geomDims    = getfilevardimsizes(f,"geometry")
			    numFeatures = geomDims(0)
	  if(numFeatures.eq.0) then
	      print("Error: gsn_add_shapefile_polylines: the number of features in this file is 0.")
	          print("       No shapefile information will be added.")
		      return(new(1,graphic))
	  end if
	    segments = f->segments
	      geometry = f->geometry
	        segsDims = dimsizes(segments)

	;---Read global attributes
	  geom_segIndex = f@geom_segIndex
	    geom_numSegs  = f@geom_numSegs
	      segs_xyzIndex = f@segs_xyzIndex
	        segs_numPnts  = f@segs_numPnts

		;---Create array to hold all polylines
		  npoly = sum(geometry(:,geom_numSegs))
	  poly  = new(npoly,graphic)

	;---Section to attach polylines to plot.
	  lon = f->x
	    lat = f->y
	      npl = 0     ; polyline counter
;
; Special check for minlat/maxlat/minlon/maxlon attributes.
;
; If set, then each lat/lon segment will be checked if it's
; in the range.  This can speed up plotting, but I need to
; verify this!
;
  if(isatt(lnres,"minlon").and.isatt(lnres,"maxlon").and.\
		       isatt(lnres,"minlat").and.isatt(lnres,"maxlat")) then
      do i=0, numFeatures-1
             startSegment = geometry(i, geom_segIndex)
	       numSegments  = geometry(i, geom_numSegs)
	       do seg=startSegment, startSegment+numSegments-1
	                 startPT = segments(seg, segs_xyzIndex)
	          endPT   = startPT + segments(seg, segs_numPnts) - 1
		            lat_sub = lat(startPT:endPT)
	          lon_sub = lon(startPT:endPT)
	          if(.not.(all(lon_sub.lt.lnres@minlon).or. \
					                     all(lon_sub.gt.lnres@maxlon).or. \
							                        all(lat_sub.lt.lnres@minlat).or. \
										                   all(lat_sub.gt.lnres@maxlat))) then
		              poly(npl) = gsn_add_polyline(wks, plot, lon_sub, lat_sub, lnres)
	            npl = npl + 1
		              end if
			                delete(lat_sub)
					delete(lon_sub)
	       end do
	           end do
		     else       ; Don't do any range checking.
		         do i=0, numFeatures-1
			        startSegment = geometry(i, geom_segIndex)
	       numSegments  = geometry(i, geom_numSegs)
	       do seg=startSegment, startSegment+numSegments-1
	                 startPT = segments(seg, segs_xyzIndex)
	          endPT   = startPT + segments(seg, segs_numPnts) - 1
		            poly(npl) = gsn_add_polyline(wks, plot, lon(startPT:endPT),  \
					                                           lat(startPT:endPT), lnres)
			              npl = npl + 1
				             end do
					         end do
						   end if
						     return(poly(0:npl-1))
	;---This is all that's needed in V6.2.0.
	end
