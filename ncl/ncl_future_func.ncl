;some function not available in ncl 5.2.0 (but available in older version), do implemention here

undef ("str_split_by_length")
function str_split_by_length(str:string, arr:integer)
local chars, lenstr, len, splitted, idx1, i, idx2
begin
    chars=stringtochar(str)
    lenstr=dimsizes(chars)
    len=dimsizes(arr)
    splitted=new((/len/), "string")
    splitted=""
    idx1=0
    do i=0, len-1
        idx2=idx1+arr(i)-1
        if(idx2 .ge. lenstr) then
            idx2=lenstr-1
        end if
        splitted(i) = chartostring(chars(idx1:idx2))
        idx1=idx2+1
        if(idx1 .ge. lenstr) then
            break
        end if
    end do
    return(splitted)
end
