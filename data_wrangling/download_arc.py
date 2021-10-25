# Import necessary libraries

# general file sorting tools
import os, argparse, sys
from ftplib import FTP
from datetime import datetime

# data wrangling tools
import pandas as pd

# argument parser
def getArgs():

   parser = argparse.ArgumentParser(
    description = '''
    Batch downloads African Rainfall Climatology (v2)
    data from the NOAA servers. The script takes two
    input parameters, the year to download and a directory
    where to store the data.

    Keep in mind that this code works only for the relatively
    small files of the ARC2 product and might fail on larger
    files if code is used in a different context.
    ''',
    epilog = '''post bug reports to the github repository''')
    
   parser.add_argument('-y',
                       '--year',
                       help = 'a year for which to download ARC data') 
    
   parser.add_argument('-d',
                       '--directory',
                       help = 'location where to store the data')

   return parser.parse_args()

# Main routine, calling subroutines above
if __name__ == '__main__':

    # parse arguments
    args = getArgs()

    # convert to string
    year = str(args.year)

    if int(args.year) < 1983:
     sys.exit("Data runs from 1983 onward only!")
    
    if not os.path.exists(args.directory):
      sys.exit("Directory does not exist, pick a different destination folder!")
    
    # start timer
    start = datetime.now()

    # login to the ftp server and change directory
    # to the correct location
    ftp = FTP("ftp.cpc.ncep.noaa.gov")
    ftp.login(user='anonymous', passwd = 'anonymous')
    ftp.cwd("/fews/fewsdata/africa/arc2/geotiff/")

    # list all remote files, very convenient!
    files = ftp.nlst()

    # convert to pandas data frame and filter out
    # the desired year
    files = pd.DataFrame(files, columns = ['filename'])
    locs = files.filename.str.contains('^africa_arc\\.' + year)
    files = files.loc[locs]

    # loop over all dates and download the files
    # in the data frame
    for index, file in files.iterrows():
     print("Downloading file: " + str(file.filename))
     file_out = args.directory + file.filename
     ftp.retrbinary("RETR " + file.filename ,open(file_out, 'wb').write)

    # wrap up
    ftp.close()
    end = datetime.now()
    diff = end - start
    print('All files downloaded for ' + str(diff.seconds) + 's')
