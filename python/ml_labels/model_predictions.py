import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os, glob
import cv2
import imgaug.augmenters as iaa
import h5py

from keras.models import load_model
from pandas.core.frame import DataFrame
import tensorflow as tf

os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = "1"

#%%
def get_predictions(Images, analysis_type_input):
    
    # load model
    if analysis_type_input == 1:
        #Growth Stage Predictions
        print('Predicting probabilities of Growth Stages ......')
        model = load_model(r'model_weights/GS_Model_FINAL.h5')
    elif analysis_type_input == 2:
        #Drought/ No drought Predictions
        print('Predicting probabilities of Drought Damage ......')
        model = load_model(r'model_weights/DR_classification_final.h5')
    elif analysis_type_input == 3:
        #Extent of damage predictions
        print('Predicting extent of Drought Damage ......')
        model = load_model(r'model_weights/DR_Extent_Final.h5')
    elif analysis_type_input == 4:
        #Multiclass damage predictions
        print('Predicting probabilities of Types of damage ......')
        model = load_model(r'model_weights/Multiclass_Final.h5')
    else:
        print('Incorrect type')
        return (False)

    # empty list
    pred_out = pd.DataFrame()
    loc = [*range(0, len(Images), 500)]

    for i in range(0,len(loc)):

        start = loc[i]

        if i == len(loc) - 1:
            end = len(Images)
        else:
            end = loc[i+1]

        l = range(start, end)
        subset = [Images[j] for j in l]

        # rescale image
        image_input, files = Resize_data(subset)

        # basenames
        names_input = []
        for file in files:
            x = os.path.basename(file)
            names_input.append(x)
        
        image_input = np.array(image_input)/255.
        names_input = np.array(names_input)

        # make predictions
        y_pred = model.predict(image_input)
        pred_df = pd.DataFrame(y_pred)
        
        # load model
        if analysis_type_input == 1:
            pred_df = pred_df.rename(columns={
                0:'sowing',
                1:'vegetative', 
                2:'flowering',
                3:'maturity',
            })
            
            pred_df['name']= names_input
            
            pred_df = pred_df[['name', 'sowing', 'vegetative', 'flowering', 'maturity']]
        elif analysis_type_input == 2:
            pred_df = pred_df.rename(columns={
                0:'no_drought',
                1:'drought', 
            })
            pred_df['name']= names_input
            pred_df = pred_df[['name', 'no_drought', 'drought']]
        elif analysis_type_input == 3:
            pred_df = pred_df.rename(columns={
                0:'extent',
            })
            pred_df['name']= names_input 
            pred_df = pred_df[['name', 'extent']]
            
        elif analysis_type_input == 4:
            pred_df = pred_df.rename(columns={
                0:'good',
                1:'weed', 
                2:'drought_conditions',
                3:'nutrient_deficient',
            })
            pred_df['name']= names_input
            pred_df = pred_df[['name', 'good', 'weed', 'drought_conditions', 'nutrient_deficient']]
        else:
            print('Incorrect type')
            return (False)
        pred_out = pred_out.append(pred_df)

    # return classifcation results
    return pred_out

def Augmentor_1(image):
    
    seq = iaa.Sequential([
        iaa.CLAHE(seed = 42)
    ])
    
    aug_imgs =  seq(image = image)
    return aug_imgs

#Image Resizing and storing with image labels 
def Resize_data(images_input):
    image_list = [] 
    name = []
    for i in range (0, len(images_input)):
        image = cv2.imread(images_input[i])
        name_img = images_input[i].split('\\')[-1]

        image = Augmentor_1(image)

        resized = cv2.resize(image, (320,240))
        image_list.append(resized)

        name.append(name_img)   
    
    return image_list, name

#%%
# list all jpg files
path = "/scratch/LACUNA/staging_data/images/"
JPG_path = os.path.join(path, "**/*.JPG")
jpg_path = os.path.join(path, "**/*.jpg")
images_JPG = glob.glob(JPG_path, recursive = True)
images_jpg = glob.glob(jpg_path, recursive = True)

# combine two jpg formats
images = images_JPG + images_jpg

#%%
print('--------- All entered images ready for predictions ----------')
print('Select the type of analysis you wish to perform')
print('1. Growth Stage'+ '\n'+ '2. Drought/No drought'+ '\n'+ '3. Extent of drought damage'+ '\n'+ '4. Multiclass damage classfication')
analysis_type =  input()

pred = get_predictions(images, int(analysis_type))

#%%
if int(analysis_type) == 1:
    print("writing data to file!")
    pred.to_csv('ml/GS_Predictions.csv')
elif int(analysis_type) == 2:
    pred.to_csv('ml/DR_Damage_Predictions.csv')
elif int(analysis_type) == 3:
    pred.to_csv('ml/DR_Extent_Predictions.csv')
elif int(analysis_type) == 4:
    pred.to_csv('ml/Multiclass_damage_Predictions.csv')
