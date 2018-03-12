;system specific
undef("rename_and_copy")
procedure rename_and_copy(orgin_file:string, dir:string)
begin   
    ft=systemfunc("basename "+orgin_file+" | cut -d . -f 1")
    ff=systemfunc("basename "+orgin_file+" | cut -d . -f 2")
    fts=str_split(ft, "_")
    nft=dimsizes(fts)
    if(nft .ne. 5) then
        print((/"Error, fail to rename & copy "/))
        print((/"ncl output figure should be named as: [VAR]_[DOM]_valid_at_[YYYYMMDDHH].[format]"/))
        print((/"then figure will be renamed as [DOM]_[VAR].[format] and copied to dir/[YYYYMMDDHH]"/))
        return
    end if
    if(fts(1) .eq. "D4") then
        fts(1)="d4"
    end if
    if(fts(1) .eq. "SZ") then
        fts(1)="d5"
    end if
    new_name=fts(1)+"_"+fts(0)+"."+ff
    new_dir=dir+"/"+fts(4)
    system("test -d "+new_dir+" || mkdir -p "+new_dir)
    system("test -e "+new_dir+"/"+new_name+" && rm -rf "+new_dir+"/"+new_name)
    print("cp "+orgin_file+" "+new_dir+"/"+new_name)
    system("cp "+orgin_file+" "+new_dir+"/"+new_name)
end
        
undef("covert_and_copyout")
procedure convert_and_copyout(figure_name, arr_dir_copyout)
local final_format, conveert, strs, nstr, file_exist, newstrs, renamed, i, new_name,ndir
begin
;SZMB machine
;a. if png, figure_name may not exist, instead: has the [file].000001.png , rename it
;b. use ~/bin/convert_png.bare.sh to do convert
;c. arr_dir_copyout is (/dir1, dir2, ../), in each dir, make a dir named date10(e.g. 2017102700), then cp figures to that date10
;   rename the figures respectively
    final_format="png"
    convert="convert -alpha off -trim +repage -density 150"
;   convert="convert -alpha off -trim +repage -density 150 +antialias"
    strs=str_split(figure_name, ".")
    nstr=dimsizes(strs)
    file_exist=tointeger(systemfunc("ls "+figure_name+" >& /dev/null && echo 1 || echo 0"))
    ;a. do rename for XX.000001.png to XX.png
    if(strs(nstr-1) .eq. "png" .and. file_exist .eq. 0) then
        newstrs=new((/nstr+1/), "string")
        newstrs(0:nstr-2) = strs(0:nstr-2)
        newstrs(nstr-1) = "000001"
        newstrs(nstr)=strs(nstr-1)
        renamed=str_join(newstrs, ".")
        file_exist=tointeger(systemfunc("ls "+renamed+"  >& /dev/null && echo 1 || echo 0"))
        if(file_exist .eq. 0) then
            print((/"both "+figure_name+" and "+renamed+" not exist, fail to convert/copy"/))
            return 
        end if
        system("mv "+renamed+" "+figure_name)
    end if
    ;b. do convert
    strs(nstr-1) = final_format
    new_name=str_join(strs, ".")
    print(convert+figure_name+" "+new_name)
    system(convert+figure_name+" "+new_name)
    ;c. do copy
    ndir=dimsizes(arr_dir_copyout)
    do i=0,ndir-1
        if(arr_dir_copyout(i) .eq. "") then
            continue
        end if
        print((/"cp "+arr_dir_copyout(i)/))
        rename_and_copy(new_name, arr_dir_copyout(i))
    end do
end

