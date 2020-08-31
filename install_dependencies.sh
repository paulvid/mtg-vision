#!/bin/bash 
BASE_DIR=$(cd $(dirname $0); pwd -L)

source $(cd $(dirname $0); pwd -L)/common.sh

 display_usage() { 
	echo "
Usage:
    $(basename "$0") [--help or -h]

Description:
    Install dependencies
"

}

# check whether user had supplied -h or --help . If yes display usage 
if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
    display_usage
    exit 0
fi 

rm -rf $BASE_DIR/cards > /dev/null 2>&1
mkdir $BASE_DIR/cards

rm -rf $BASE_DIR/training > /dev/null 2>&1
mkdir $BASE_DIR/training

#Install Tensorflow
pip3 install tensorflow==1.15

#Prerequisite for Tensorflow Models
pip3 install pillow lxml jupyter matplotlib opencv-python

#Clone Tensorflow Model Git Repo and Build Project
rm -rf $BASE_DIR/tensorflow > /dev/null 2>&1
mkdir -p $BASE_DIR/tensorflow
cd $BASE_DIR/tensorflow
git clone https://github.com/tensorflow/models.git
cd $BASE_DIR/tensorflow/models/research
python setup.py build
python setup.py install

#Download Original Tensorflow Model
cd $BASE_DIR
rm -rf $BASE_DIR/pre-trained-model > /dev/null 2>&1
mkdir -p $BASE_DIR/pre-trained-model
cd $BASE_DIR/pre-trained-model
wget http://download.tensorflow.org/models/object_detection/ssd_inception_v2_coco_2018_01_28.tar.gz
tar -xzf ssd_inception_v2_coco_2018_01_28.tar.gz

#Install Tensorflow - Object Detection Tools

#COCO API Install
cd $BASE_DIR
rm -rf $BASE_DIR/coco > /dev/null 2>&1
mkdir -p $BASE_DIR/coco
cd $BASE_DIR/coco
git clone https://github.com/cocodataset/cocoapi.git
cd $BASE_DIR/coco/cocoapi/PythonAPI
make
cp -r pycocotools $BASE_DIR/tensorflow/models/research/
# cd $BASE_DIR/tensorflow/models/research/
# protoc object_detection/protos/*.proto --python_out=.

#Install Protobuffer Writers
brew install protobuf

# From tensorflow/models/research/
cd $BASE_DIR/tensorflow/models/research
protoc object_detection/protos/*.proto --python_out=.

# From tensorflow/models/research/
cd $BASE_DIR/tensorflow/models/research
PYTHONPATH=''
export PYTHONPATH=$PYTHONPATH:`pwd`:`pwd`/slim

cd $BASE_DIR
git clone https://github.com/Paperspace/DataAugmentationForObjectDetection.git

#Export Inference Graph From Home Directory
cd $BASE_DIR
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/slim
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/object_detection

#Image labelling
pip3 install labelImg
