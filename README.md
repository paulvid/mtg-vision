# MTG Card Identification

![Urza](urza.gif)

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
RUN apt-get update -y && apt-get install -y curl
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

This step is transfer learning; it retrains the ssd_inception_v2_coco model with images generated.
*Note: you can stop the training at any time by ctrl-c; training will restart based on last checkpoint*

### Training the model
```
./train_card_model.sh "[name_of_your_card]"
```

### Example execution
```
INFO:tensorflow:Restoring parameters from training/model.ckpt-35523
I0911 08:19:35.095611 4504698304 saver.py:1284] Restoring parameters from training/model.ckpt-35523
WARNING:tensorflow:From /usr/local/lib/python3.5/site-packages/tensorflow_core/python/training/saver.py:1069: get_checkpoint_mtimes (from tensorflow.python.training.checkpoint_management) is deprecated and will be removed in a future version.
Instructions for updating:
Use standard file utilities to get mtimes.
W0911 08:19:37.186553 4504698304 deprecation.py:323] From /usr/local/lib/python3.5/site-packages/tensorflow_core/python/training/saver.py:1069: get_checkpoint_mtimes (from tensorflow.python.training.checkpoint_management) is deprecated and will be removed in a future version.
Instructions for updating:
Use standard file utilities to get mtimes.
INFO:tensorflow:Running local_init_op.
I0911 08:19:37.188764 4504698304 session_manager.py:500] Running local_init_op.
INFO:tensorflow:Done running local_init_op.
I0911 08:19:37.823971 4504698304 session_manager.py:502] Done running local_init_op.
INFO:tensorflow:Starting Session.
I0911 08:19:46.453855 4504698304 learning.py:746] Starting Session.
INFO:tensorflow:Saving checkpoint to path training/model.ckpt
I0911 08:19:46.915580 123145594753024 supervisor.py:1117] Saving checkpoint to path training/model.ckpt
INFO:tensorflow:Starting Queues.
I0911 08:19:46.916985 4504698304 learning.py:760] Starting Queues.
INFO:tensorflow:global_step/sec: 0
I0911 08:19:56.785290 123145589497856 supervisor.py:1099] global_step/sec: 0
WARNING:tensorflow:From /usr/local/lib/python3.5/site-packages/tensorflow_core/python/training/saver.py:963: remove_checkpoint (from tensorflow.python.training.checkpoint_management) is deprecated and will be removed in a future version.
Instructions for updating:
Use standard file APIs to delete files with this prefix.
W0911 08:19:58.277100 123145594753024 deprecation.py:323] From /usr/local/lib/python3.5/site-packages/tensorflow_core/python/training/saver.py:963: remove_checkpoint (from tensorflow.python.training.checkpoint_management) is deprecated and will be removed in a future version.
Instructions for updating:
Use standard file APIs to delete files with this prefix.
INFO:tensorflow:Recording summary at step 35524.
I0911 08:20:00.494594 123145584242688 supervisor.py:1050] Recording summary at step 35524.
INFO:tensorflow:global step 35525: loss = 1.4406 (15.729 sec/step)
I0911 08:20:03.369996 4504698304 learning.py:512] global step 35525: loss = 1.4406 (15.729 sec/step)
INFO:tensorflow:global step 35526: loss = 1.2294 (2.307 sec/step)
I0911 08:20:06.243526 4504698304 learning.py:512] global step 35526: loss = 1.2294 (2.307 sec/step)
INFO:tensorflow:global step 35527: loss = 1.5024 (2.261 sec/step)
I0911 08:20:08.504751 4504698304 learning.py:512] global step 35527: loss = 1.5024 (2.261 sec/step)
INFO:tensorflow:global step 35528: loss = 1.1537 (2.297 sec/step)
I0911 08:20:10.802378 4504698304 learning.py:512] global step 35528: loss = 1.1537 (2.297 sec/step)
INFO:tensorflow:global step 35529: loss = 1.4092 (3.402 sec/step)
I0911 08:20:14.204577 4504698304 learning.py:512] global step 35529: loss = 1.4092 (3.402 sec/step)
INFO:tensorflow:global step 35530: loss = 1.0272 (2.508 sec/step)
I0911 08:20:16.713088 4504698304 learning.py:512] global step 35530: loss = 1.0272 (2.508 sec/step)
INFO:tensorflow:global step 35531: loss = 0.9695 (2.366 sec/step)
I0911 08:20:19.079914 4504698304 learning.py:512] global step 35531: loss = 0.9695 (2.366 sec/step)
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

# Debugging

Like mentioned before, this is very much experimental.
However, I tried to push the logs to the `logs` folder. That should help :) 

# Author & Contributors

**Paul Vidal** - [LinkedIn](https://www.linkedin.com/in/paulvid/)