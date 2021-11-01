# Overview

The privacy screen workflow relies on two key parts. The first part is the Places365 VGG16 CNN model which screens for the presence of (natural) vegetation. A second stage (if a field is present) is the screening for faces using the MTCNN model. If a face is detected in a field this area will be blanked out. This option will only become active using a parameter flag as this would require copying the files to a new location rather than just providing a meta-data output file with labels.

## Places365

The Keras models has been obtained by directly converting the [Caffe models](https://github.com/CSAILVision/places365) provived by the authors (all the original Caffe-based resources can be found at the link). The conversion of Keras were made by Grigorios Kalliatakis. Changes were made to fit the purpose of this project. Citations to the repo would therefore be appropriate.

## MTCNN

Implementation of the [MTCNN face detector](https://github.com/ipazc/mtcnn) for Keras written from scratch by Iván de Paz Centeno based on the paper Zhang, K et al. (2016).

Please reference both repositories in addition to acknowledging license requirements.

## System Requirements

- Python 3.4+
- Tensorflow 2.6
- Keras 2.6
- numpy and pandas
- opencv

## Running a screening test

```python
python3 lacuna_privacy_screen.py -d /backup/see_it_grow/ -o /scratch/LACUNA/data_product/images/
```

## Licensing

- The VGG16-places365 weights were released by [landmark-recognition-challenge](https://github.com/antorsae/landmark-recognition-challenge) under the [GNU General Public License v3.0](https://github.com/antorsae/landmark-recognition-challenge/blob/master/LICENSE)

- both Keras implementations of Places365 and MTCNN are distributed under an MIT license
