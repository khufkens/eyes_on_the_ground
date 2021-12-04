# Eyes on the ground <img src='logo.jpg' align="right" height="50" />

## Providing quality model training data through smartphone images of crops

The 'Eyes on the Ground' project is a collaboration between IFPRI/CGIAR, the Lacuna Fund to create a large machine learning (ML) dataset of smallholder farmer's fields based upon previous work within the Picture Based Insurance framework (Ceballos 2019).

These images provide information on the progression of the growing season and a direct assessment of the corp status by visual means. Within the context of insurance image derived metrics can be seen as equivalent to index based insurance. However, evaluating these images manually is time intensive and does not scale well.

The codebase as presented in this repository serves a number of purposes as listed below. The goal is to provide an annotated data set of >35K images in order to support ML model development to address the annotation and detection of crop status (disease, disturbance). Within the context of the project BlueGreen Labs provided data processing code, [SpatioTemporal Asset Catalog (STAC)](https://stacspec.org/) formatting as well as training. BlueGreen Labs historically was key in developing the underlying picture based insurance protocols (Hufkens et al. 2018). For a full workflow on all these topics we refer to the individual articles. This data will be a valuable contribution to applications such as crop modeling, agricultural finance and insurance, agricultural advisories, and early warning systems. 

### 1. Privacy screening

Crop images are collected by farmers in support of insurance practices and crop monitoring. However, oversight, inexperience with digital technology can lead to situations where people's private property or recognizable faces are present within a dataset which will be distributed widely and openly. This presents a clear privacy issue in violation with Internal Review Board requirements and consent agreements. Historically, manual screening was applied. However, with growing field trials this is not a long term solution. As such, an automated filter should relieve some of the burden. Here, we use existing deep learning models to screen crops for non-vegetation images and human faces. Data allows for the screening of a single image or a whole directory of images (recursively parsed) with results returne as a CSV file for post-processing.

### 2. Ancillary data remote sensing

A second part of the processing requires amending seasonal crop image with ancillary remote sensing data and climate data for machine learning purposes. Remote sensing data will be stripped of geographic location data to provide anonymous but meaningful data for remote sensing analysis together with the original field based images. Data will be formatted as STAC compliant (see 3).

### 3. STAC processing

The above data is then compiled into a STAC catalogue, with the following structure. The focus here is on the image data, keeping the remote sensing data separate. The remote sensing data can however easily be merged to provide a consistent (machine learning) dataset. Note that no interpolation is done on the data products to retain the original data as much as possible. The latter is up to the user as many different interpolation strategies exist.

## Project partners

This project is a collaboration between the Lacuna Fund, ACRE Africa, IFPRI, CGIAR Big Data, and Radiant Earth.

### References

- Ceballos F., Kramer B., Robles M. The feasibility of picture-based insurance (PBI): Smartphone pictures for affordable crop insurance. (2019) Development Engineering, 4, 100042. ([PDF](https://www.sciencedirect.com/science/article/pii/S2352728518300812))

- Hufkens K, Melaas EK, Mann ML, Foster T, Ceballos F, Robles M, Kramer B. Monitoring crop phenology using a smartphone based near-surface remote sensing approach. (2018) Agricultural and Forest Meteorology, 265, 327–337. ([PDF](https://www.sciencedirect.com/science/article/pii/S0168192318303484))

- https://gitlab.com/ACRE_Africa/pbi-image-processing/-/tree/Akanodia-main-patch-30123