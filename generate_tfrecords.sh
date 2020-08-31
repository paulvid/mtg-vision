#!/bin/bash 
BASE_DIR=$(cd $(dirname $0); pwd -L)

source $(cd $(dirname $0); pwd -L)/common.sh

 display_usage() { 
	echo "
Usage:
    $(basename "$0") <normalized_card_name> [--help or -h]

Description:
    Augments card image

Arguments:
    path: path to your card folder (oracle id)
"

}

# check whether user had supplied -h or --help . If yes display usage 
if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
    display_usage
    exit 0
fi 


# Check the numbers of arguments
if [  $# -lt 1 ] 
then 
    echo "Not enough arguments!"  >&2
    display_usage
    exit 1
fi 

if [  $# -gt 1 ] 
then 
    echo "Too many arguments!"  >&2
    display_usage
    exit 1
fi 

normalized_card_name=$1
PYTHONPATH=''
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/slim
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/object_detection

#Create New Dirs
rm -rf mkdir $BASE_DIR/cards/$normalized_card_name/test/tfrecord/ > /dev/null 2>&1
mkdir $BASE_DIR/cards/$normalized_card_name/test/tfrecord/
rm -rf mkdir $BASE_DIR/cards/$normalized_card_name/train/tfrecord/ > /dev/null 2>&1
mkdir $BASE_DIR/cards/$normalized_card_name/train/tfrecord/


python3 $BASE_DIR/generate_tfrecord.py \
--csvInput=$BASE_DIR/cards/$normalized_card_name/train_labels_DA.csv \
--imgPath=$BASE_DIR/cards/$normalized_card_name/train/DA/  \
--outputPath=$BASE_DIR/cards/$normalized_card_name/train/tfrecord/train.record \
--label=$normalized_card_name 


python3 $BASE_DIR/generate_tfrecord.py \
--csvInput=$BASE_DIR/cards/$normalized_card_name/test_labels_DA.csv \
--imgPath=$BASE_DIR/cards/$normalized_card_name/test/DA/  \
--outputPath=$BASE_DIR/cards/$normalized_card_name/test/tfrecord/test.record \
--label=$normalized_card_name 
