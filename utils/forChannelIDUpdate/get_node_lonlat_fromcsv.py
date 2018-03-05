#!/usr/bin/env python
import numpy
from scipy.io import netcdf
import sys,getopt
import csv


def help():
    print '''
Usage: get_node_lonlat_fromcsv.py -i <input_csv_file> -d <chrtout_data_file> -o <output_csv_file>

Function: will read the "node_index" column (index starts on 1), CHRTOUT file, and generate a csv with "node_index, node_lon, node_lat" columns 
'''
    sys.exit()
    

#parse arguments (inputfile, outputfile)
argvx=sys.argv[1:] 
icsv=''
ocsv=''
inc=''
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
list_chan_idx=[]
with open(icsv, 'rb') as fb:
    dictReader = csv.DictReader(fb)
    for row in dictReader:
        list_chan_idx.append(int(row["node_index"]))

#read nc
nc=netcdf.netcdf_file(inc, "r", mmap=False)
lon=nc.variables["longitude"].data
lat=nc.variables["latitude"].data
xlon=[lon[i-1] for i in list_chan_idx]
xlat=[lat[i-1] for i in list_chan_idx]
nc.close()
#output ocsv
with open(ocsv, 'wb') as fb:
    writer = csv.writer(fb)
    writer.writerow(["node_index","node_lon","node_lat"])
    for (i,lo,la) in zip(list_chan_idx, xlon, xlat):
        writer.writerow([i,lo,la])



