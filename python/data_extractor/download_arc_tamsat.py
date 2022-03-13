#!/usr/bin/env python3

# ---------------------------------------------
# Downloads gridded rainfall data
# from the African Rainfall Climatology (v2)
# product repository as well as from the
# TAMSAT rainfall product at the U. Reading
# ---------------------------------------------

# Import necessary libraries
import os, argparse, sys
import zipfile
import urllib3
import shutil
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

   parser.add_argument('-m',
                       '--month',
                       default = '',
                       help = 'a month of year for which to download ARC data') 

   parser.add_argument('-p',
                       '--product',
                       default= 'ARC',
                       help = 'which product to download, ARC or TAMSAT')

   parser.add_argument('-d',
                       '--directory',
                       help = 'location where to store the data')

   return parser.parse_args()

# Main routine, calling subroutines above
if __name__ == '__main__':

    # TAMSAT base url daily product
    base_url = "http://gws-access.jasmin.ac.uk/public/tamsat/rfe/data/v3.1/daily"

    # parse arguments
    args = getArgs()

    # convert to string
    year = str(args.year)
    month = str(args.month)

    if int(args.year) < 1983:
     sys.exit("Data runs from 1983 onward only!")
    
    if not os.path.exists(args.directory):
      sys.exit("Directory does not exist, pick a different destination folder!")
    
    if args.product == "ARC":

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
      locs = files.filename.str.contains('^africa_arc\\.' + year + month)
      files = files.loc[locs]

      # loop over all dates and download the files
      # in the data frame
      for index, file in files.iterrows():
       print("Downloading file: " + str(file.filename))
       file_out = args.directory + file.filename
       ftp.retrbinary("RETR " + file.filename ,open(file_out, 'wb').write)

       try:
         with zipfile.ZipFile(file_out) as z:
           z.extractall(args.directory)
           print("Extracted geotiff")
           os.remove(file_out)
       except:
         print("Invalid file")

      # wrap up
      ftp.close()
      end = datetime.now()
      diff = end - start
      print('All files downloaded for ' + str(diff.seconds) + 's')

    elif args.product == "TAMSAT":
      
      # list all dates
      dates = pd.date_range(start='1/1/' + year, end='12/31/' + year)
      df = pd.DataFrame(dates, columns = ['date'])
      locs = df.date.dt.strftime('%Y-%m-%d').str.contains(year + "-" + month)
      df = df.loc[locs].reindex()
     
      # date conversions
      df['year'] = df.date.dt.strftime('%Y')
      df['month'] = df.date.dt.strftime('%m')
      df['date'] = df.date.dt.strftime('%Y_%m_%d')

      for index, file in df.iterrows():

        url = base_url + "/" + file.year + "/" + file.month + "/rfe" + file.date + ".v3.1.nc"
        filename = args.directory + "/rfe" + file.date + ".v3.1.nc"

        http = urllib3.PoolManager()
        with open(filename, 'wb') as out:
            r = http.request('GET', url, preload_content=False)
            shutil.copyfileobj(r, out)
        r.release_conn()

    else:
      sys.exit("Wrong product name, use either ARC or TAMSAT")
