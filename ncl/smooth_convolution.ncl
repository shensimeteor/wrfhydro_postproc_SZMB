undef("get_conv2d_avg")
;get the "average" convolution kernel (2d-array)
function get_conv2d_avg(n1:integer, n2:integer)
local mat2d
begin
    mat2d=new((/n1,n2/), "float")
    mat2d=1.0/(n1*n2)
    return(mat2d)
end

undef("conv2d_2darray")
;use defined convolution kernel h(must be odd size), to smooth/conv the 2darray
; opt_conv:
; - 1, size shrinked (no fill near border)
; - 2, size same, fill array2d@missing near border
function conv2d_2darray(h: numeric, array2d: numeric, opt_conv: integer)
local dims_array, nx, ny, dims_h, n1, n2, nrt1, nrt2, ret_array, i, j, ix_sta, ix_end, iy_sta, iy_end
begin
    dims_array=dimsizes(array2d)
    nx=dims_array(0)
    ny=dims_array(1)
    dims_h=dimsizes(h)
    n1=dims_h(0)
    n2=dims_h(1)
    if(mod(n1, 2) .eq. 0 .or. mod(n2,2) .eq.  0) then
        print((/"in conv2d_2darray, dimsizes of h must be odd, no even"/))
        exit
    end if
    if(opt_conv .eq. 1) then
        nrt1=nx-n1+1
        nrt2=ny-n2+1
        ret_array=new((/nrt1, nrt2/), "float")
        do i=0, nrt1-1
            ix_sta=i
            ix_end=i+n1-1
            do j=0, nrt2-1
                iy_sta=j
                iy_end=j+n2-1
                ret_array(i,j)=sum(h * array2d(ix_sta:ix_end, iy_sta:iy_end))
            end do
        end do
        return(ret_array)
    end if
    if(opt_conv .eq. 2) then
        nrt1=nx
        nrt2=ny
        n1_half = (n1 - 1) / 2
        n2_half = (n2 - 1) / 2
        ret_array=new((/nrt1, nrt2/), "float")
        do i=0, nrt1-1
            ix_sta=i - n1_half
            ix_end=i + n1_half
            do j=0, nrt2-1
                iy_sta=j - n2_half
                iy_end=j + n2_half
                if(ix_sta .lt. 0 .or. ix_end .ge. nx .or. iy_sta .lt. 0 .or. iy_end .ge. ny) then
                    ret_array(i,j) = array2d@missing_value
                else
                    ret_array(i,j)=sum(h * array2d(ix_sta:ix_end, iy_sta:iy_end))
                end if
            end do
        end do
        return(ret_array)
    end if
    print((/"Now only opt_conv == 1 is supported!"/))
end

