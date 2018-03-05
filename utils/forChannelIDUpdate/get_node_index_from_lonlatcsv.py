#!/usr/bin/env python
import numpy as np
from scipy.io import netcdf
import sys,getopt
import csv


def help():
    print '''
Usage: get_node_index_from_lonlatcsv.py -i <input_csv> -o <output_csv> -d <chrtout_nc> 

Function: read input_csv to get "node_lon", "node_lat" row, read chrtout_nc to get lons/lats, find the new index of nodes 
'''
    sys.exit()
    

#parse arguments (inputfile, outputfile)
argvx=sys.argv[1:] 
icsv=''
ocsv=''
inc=''
rad=0.001
try:
    opts, args = getopt.getopt(argvx,"hi:d:o:",["help", "icsv=","inc=","ocsv="])
except getopt.GetoptError:
    help()
for opt, arg in opts:
    if opt in ("-h", "--help"):
        help()
    elif opt in ("-i", "--icsv"):
        icsv=arg
    elif opt in ("-o", "--ocsv"):
        ocsv=arg
    elif opt in ("-d", "--inc"):
        inc=arg
if(not (icsv and ocsv and inc)):        
    help()

#read icsv
icsv_lonlat=[]
with open(icsv, 'rb') as fb:
    dictReader = csv.DictReader(fb)
    for row in dictReader:
        lon=float(row["node_lon"])
        lat=float(row["node_lat"])
        icsv_lonlat.append((lon,lat))        

#read nc
nc=netcdf.netcdf_file(inc, "r", mmap=False)
lons=np.asarray(nc.variables["longitude"].data)
lats=np.asarray(nc.variables["latitude"].data)
nc.close()

#find nearest index
node_idx=[]
cnt=0
for lon,lat in icsv_lonlat:
    dis=np.sqrt((lons-lon)**2 + (lats-lat)**2)
    idx=np.argmin(dis)
    if(dis[idx] < rad):
        node_idx.append(idx+1)
    else:
        print("Warning, for (%i, %f, %f), can't find nearby node, the nearest node's distance=%f" %(cnt, lon, lat, dis[idx]))
        node_idx.append(np.nan)
    cnt+=1

#output ocsv
with open(ocsv, 'wb') as fb:
    writer = csv.writer(fb)
    writer.writerow(["node_lon","node_lat", "new_node_index"])
    for (i,ll) in zip(node_idx,icsv_lonlat):
        lo,la=ll
        writer.writerow([lo,la,i])



