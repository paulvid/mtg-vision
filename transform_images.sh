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

#Create New Dirs
rm -rf mkdir $BASE_DIR/cards/$normalized_card_name/test/pickle/ > /dev/null 2>&1
mkdir $BASE_DIR/cards/$normalized_card_name/test/pickle/
rm -rf mkdir $BASE_DIR/cards/$normalized_card_name/train/pickle/ > /dev/null 2>&1
mkdir $BASE_DIR/cards/$normalized_card_name/train/pickle/
rm -rf mkdir $BASE_DIR/cards/$normalized_card_name/test/DA/ > /dev/null 2>&1
mkdir $BASE_DIR/cards/$normalized_card_name/test/DA/
rm -rf mkdir $BASE_DIR/cards/$normalized_card_name/train/DA/ > /dev/null 2>&1
mkdir $BASE_DIR/cards/$normalized_card_name/train/DA/


#Data Augmentation - Create Synthetic Training Images
python3 $BASE_DIR/transformImages.py \
    --inputDir=$BASE_DIR/cards/$normalized_card_name/test/ \
    --numIters=100 \
    --imageLabelFile=$BASE_DIR/cards/$normalized_card_name/test_labels.csv \
    --outputPath=$BASE_DIR/cards/$normalized_card_name/test_labels_DA.csv \
    --label=$normalized_card_name 

#Create Training Set
python3 $BASE_DIR/transformImages.py \
    --inputDir=$BASE_DIR/cards/$normalized_card_name/train/ \
    --numIters=100 \
    --imageLabelFile=$BASE_DIR/cards/$normalized_card_name/train_labels.csv \
    --outputPath=$BASE_DIR/cards/$normalized_card_name/train_labels_DA.csv \
    --label=$normalized_card_name 

#Create Test Set
