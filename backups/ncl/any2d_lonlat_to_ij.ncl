undef("any2d_lonlat_to_ij")
;for any regular grid (lon,lat) (lon/lat are 2d-array), given scalar lonpt, latpt, find the nearest i,j
; (i for x-dim, j for y-dim, lon(j,i) nearest to pt) by finding the nearest distance
function any2d_lonlat_to_ij(lon2d: numeric, lat2d: numeric, lonpt: numeric, latpt:numeric)
local lon1d, lon2d, dims, dis2, minidx, ij, idx
begin
    lon1d=ndtooned(lon2d)
    lat1d=ndtooned(lat2d)
    dims=dimsizes(lon2d)
    dis2=(lon1d - lonpt)^2 + (lat1d - latpt)^2
    minidx=minind(dis2)
    idx=tointeger((/floor(minidx/dims(1)), mod(minidx, dims(1))/))
    ;print((/"-- in any2d_lonlat_to_ij"/))
    ;print((/lonpt, latpt, sqrt(min(dis2)), minidx/))
    ;print((/idx/))
    ;print((/lon2d(idx(0), idx(1)), lat2d(idx(0), idx(1))/))
    ;print((/"out any2d_lonlat_to_ij"/))
    return(idx)
end
