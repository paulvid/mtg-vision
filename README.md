

# MTG Card Identification

This project is based on the work by the Data Jedi Ian Brooks (see [LogoTL repo](https://github.com/BrooksIan/LogoTL)).
Its goal is to identify a magic the gathering card based on its picture, running on a Coral TPU dev board.

This repository is built to work both on MacOS X and Ubuntu on Cloudera Machine Learning, as detailed below.
The advantage of running with Cloudera Machine Learning is the ability to train the model and leverage GPU for deep learning.

*Note: This is very much a work in progress and a simple example a lot of work remains to be done to map the entire MTG card base*

# Pre-Requisites
## Cloudera Machine Learning

For Cloudera Machine Learning, use this custom engine:

```
FROM docker.repository.cloudera.com/cdsw/engine:13

RUN apt-get update && apt-get install -y --no-install-recommends \
gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 10.0.130

ENV CUDA_PKG_VERSION 10-0=$CUDA_VERSION-1

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION \
cuda-compat-10-0 && \
ln -s cuda-10.0 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411"
# ---- End of generated content ----
# ---- Based on generated code from: https://gitlab.com/nvidia/container-images/cuda/raw/master/dist/ubuntu18.04/10.0//runtime/Dockerfile ----

ENV NCCL_VERSION 2.4.8

RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-$CUDA_PKG_VERSION \
cuda-nvtx-$CUDA_PKG_VERSION \
libnccl2=$NCCL_VERSION-1+cuda10.0 && \
    apt-mark hold libnccl2 && \
    rm -rf /var/lib/apt/lists/*
# ---- End of generated content ----
# ---- Based on generated code from: https://gitlab.com/nvidia/container-images/cuda/raw/master/dist/ubuntu18.04/10.0//runtime/cudnn7/Dockerfile ----

ENV CUDNN_VERSION 7.6.5.32
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcudnn7=$CUDNN_VERSION-1+cuda10.0 \
&& \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*
# ---- End of generated content ----

RUN apt-get update -y && apt-get install -y jq
```


## MacOS X 10.15
- jq
- python 3.5
- docker (to run edgetpu_compiler)

# Step-By-Step Instructions

## Overview

The project executes the following steps:
1. Install dependencies (self explanatory) 
2. Download card database from [scryfall.com API](https://scryfall.com) 
3. Download card by name (or reuse example card)
4. Split images in test/train folders
5. Runs data augmentation using this [library](https://github.com/Paperspace/DataAugmentationForObjectDetection)
6. Transfer learning: re-trains ssd_inception_v2_coco model with images generated
7. Packages TF model to run on edge_tpu

## Step 1: Dependencies

**Description:**

This step is self explanatory: install the different dependencies needed for this project, including:
- pip3 libraries
- tensorflow models
- data augmentation libraries

## Cloudera Machine Learning
```
./install_dependencies_ubuntu.sh
```

### MacOS X 10.15
```
./install_dependencies_mac.sh
```

## Step 2: Card Data preparation

**Description:**

This step is preparing data for training, including:
- Downloading card database from [scryfall.com API](https://scryfall.com) 
- Downloading card by name (or reuse example card)
- Splitting images in test/train folders
- Running data augmentation using this [library](https://github.com/Paperspace/DataAugmentationForObjectDetection)

### Re-use example (Urza, High Lord Artificer)
```
./prepare_example_card_for_model.sh
```

### Preparing one card (from scryfall API)
```
./prepare_card_for_model.sh "[name_of_your_card]"
```


### Example execution
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Starting to prepare card data ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⏱  0751hrs

❎ card db already downloaded
✅ card example copied
✅ card data split completed                                 
✅ csv label generation completed                                 
✅ data augmentation completed                                 
✅ tf records augmentation completed                                 

⏱  0802hrs

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Finished to prepare card data ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```


## Step 3: Model training

**Description:**

This step is transfer learning; it retrains the ssd_inception_v2_coco model with images generated

### Training the model
```
./train_card_model.sh "[name_of_your_card]"
```

### Example execution
```


```


## Step 4: Model packaging

**Description:**

This step packages the a checkpoint model to TFLite, and compiles it for edge TPU.

### Cloudera Machine Learning
```
./package_model_ubuntu.sh [checkpoint_number]
```


### MacOS X 10.15
```
./package_model_mac.sh [checkpoint_number] [IP of your TPU]
```

### Example Execution
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Starting to package model ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⏱  0814hrs

✅ creating tf lite completed                                 
✅ model compiled for edge tpu
✅ model uploaded to TPU
✅ Package completed; run your model: edgetpu_detect_server --model mtg/LogoObjD_edgetpu.tflite --label mtg/label.txt --threshold=0.51

⏱  0815hrs

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Finished to package model ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```


# Author & Contributors

**Paul Vidal** - [LinkedIn](https://www.linkedin.com/in/paulvid/)