#!/usr/bin/env python

# Import necessary libraries

# general file sorting tools
import os, argparse, glob, sys

# data wrangling tools
import numpy as np
import pandas as pd

# image processing
from PIL import Image
from cv2 import resize
import cv2 as cv

# Deep learning models
from places_model import VGG16_Places365
from mtcnn.mtcnn import MTCNN

# argument parser
def getArgs():

   parser = argparse.ArgumentParser(
    description = '''
    Screens PBI images for final compilation into a
    a coherent dataset. The routine removes all non-vegetation images
    recorded by accident by participants in the trials. In addition the
    routine screens for faces such that these images can be removed as
    well to ensure privacy. Results are reported in a simple CSV file
    for ease of re-use and compatibility reasons. This routine can easily
    be adjusted to output data to a database or JSON data.
    
    By default, when providing a directory of images to evaluate, only
    images with the JPG extension will be considered. You can change
    the extension using a command line flag.
    ''',
    epilog = '''post bug reports to the github repository''')
    
   parser.add_argument('-f',
                       '--file',
                       help = 'a single file location to process') 
    
   parser.add_argument('-d',
                       '--directory',
                       help = 'location of image data')

   parser.add_argument('-o',
                       '--output_directory',
                       help = 'location where to store the output data',
                       default = '.')

   parser.add_argument('-e',
                       '--extension',
                       help = 'image file extension to consider when providing a directory',
                       default = ['JPG','jpg'])

   return parser.parse_args()


# routine to label images using the Places365 database
# trained CNN and the MTCNN trained face detector
# the routine assumes that both models are loaded
# into main

def label_image(file):
     
     # read in image, if this fails
     # return NA
     try:
      image = Image.open(file)
     except:
      results = {'field': "NA",
         'accuracy': "NA",
         'file' : os.path.basename(file),
         'people' : "NA",
         'class' : "NA"
        }
      return(results)
     
     
     # Check the size of the image, if too small
     # <224px then skip / return NA upsampling
     # breaks the algorithms
     # it is also unreasonable to expect good
     # content evaluation from such small images
     # at best colour based indices can be
     # extracted
     width, height = image.size
     
     if (width < 224 or height < 224):
      results = {'field': "NA",
         'accuracy': "NA",
         'file' : os.path.basename(file),
         'people' : "NA",
         'class' : "NA"
        }
      return(results)
     
     # resize the data to fit the keras
     # workflow
     image = np.array(image, dtype=np.uint8)
     cv_image = np.array(image)
     
     image = resize(image, (224, 224))
     image = np.expand_dims(image, 0)
          
     # only return the top scoring prediction
     predictions_to_return = 1
    
     # run the model and return the prediction for the
     # image at hand
     preds = places_model.predict(image)[0]
     top_preds = np.argsort(preds)[::-1][0:predictions_to_return]
     accuracy = preds[top_preds[0]]

     # for debugging we can read the class label
     file_name = 'categories_places365.txt'
    
     # create empty class list
     classes = list()
     with open(file_name) as class_file:
         for line in class_file:
             classes.append(line.strip().split(' ')[0][3:])
     classes = tuple(classes)

     # output the prediction
     #for i in range(0, predictions_to_return):
     #    print(classes[top_preds[i]]) # class as text
     #    print(top_preds[i]) # acceptable classes number

     # a vector of acceptable classes (fields, grass, etc)
     # not comprehensive yet, screen all classes!!!
     #
     # alternatively the last layer is removed and the
     # model retrained, but this would require valid
     # training data.
     
     acceptable_classes = [
     36, 30, 48, 62, 110,
     116,117, 138, 145,
     104, # corn field
     140,141,142,
     150, 151, 152,153,
     164, 173, 204, 205,
     209, 224, 229, 232,
     233, 234, 243, 249,
     254, 258, 265, 271,
     287, # rice paddy
     288, 323, 338, 341,
     345, 349,
     359, # wheat field
     362, 364
     ]

     # If the image is a field or similar evaluate
     # it for the presence of persons / faces
     if top_preds[0] in acceptable_classes:
      field = "yes"
      people = "NA"
        
      # by default, if there isn't a field not faces
      # need to be detected. As such, if it is a field
      # we add another layer of security in order to 
      # detect faces in the  field of view. This to
      # disqualify the image for public release to
      # ensure no private data is leaked
      faces = face_detector.detect_faces(cv_image)
      if faces:
       prob = []
       for face in faces:
        val_list = list(face.values())
        prob.append(val_list[1])
        people = max(list(prob))              

     else:
      field = "no"
      people = "NA" # indoor scenes should be removed by default
            
     # return data
     results = {'field': field,
      'accuracy': accuracy,
      'file' : os.path.basename(file),
      'people' : people,
      'class' : classes[top_preds[0]]
      }
      
     return(results)


# Main routine, calling subroutines above
if __name__ == '__main__':

    # parse arguments
    args = getArgs()
    
    # if file is provided list file
    # else list directory
    
    if args.file is not None:
     if os.path.exists(args.file):
      files = [args.file]
     else:
      sys.exit("File doesn't exist")
    else:
     if args.directory is not None:
     
      # empty file list
      files = list()
      for i, ext in enumerate(args.extension):
       print(ext)
       tmp = glob.glob(args.directory + '/**/*.' + ext, recursive=True)
       files.extend(tmp)
       
      if len(files) == 0:
        sys.exit("Directory does not contain images")
     else:
      sys.exit("No file or directory provided")

    # read in the places model (weights are
    # stored in the local ~/.keras directory)
    # and downloaded from the repo
    places_model = VGG16_Places365(weights='places')
    
    # read in the face detection model
    face_detector = MTCNN()
    
    # create empty output dataframe
    results = pd.DataFrame(columns=['field','accuracy'])

    # iterate over all images and label them
    for i, file in enumerate(files[0:100]):
     
     tmp = label_image(file)
     results = results.append(
       tmp,
       ignore_index=True)
       
    print(results)
