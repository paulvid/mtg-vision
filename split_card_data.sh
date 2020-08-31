#!/bin/bash 
BASE_DIR=$(cd $(dirname $0); pwd -L)

 display_usage() { 
	echo "
Usage:
    $(basename "$0") <path> [--help or -h]

Description:
    Splits card dataset 80/20 for train/test

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


folder=$1

# Creating folders
rm -rf $folder/train > /dev/null 2>&1
rm -rf $folder/test > /dev/null 2>&1
mkdir $folder/train
mkdir $folder/test


# Calculate the number of train vs test
train_percent=0.8
test_percent=0.2
num_cards=$(ls -1q "$folder"/*.jpg | wc -l)
num_train=$(awk -v c="$num_cards" -v p=$train_percent "BEGIN {printf \"%.0f\n\", c*p}")

# Moves files around
i=1
for path in $(ls "$folder"/*.jpg)
do 
    
    filename=$(echo $path | awk -F "/" '{print $NF}')
    xml_filename=$(echo $path | awk -F "." '{print $1".xml"}' | awk -F "/" '{print $NF}')

    if [ $i -le $num_train ]
    then
        mv $folder/$filename $folder/train/$filename 
        mv $folder/$xml_filename $folder/train/$xml_filename 
    else
        mv $folder/$filename $folder/test/$filename 
        mv $folder/$xml_filename $folder/test/$xml_filename 
    fi
    let i++
done