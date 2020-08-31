#!/bin/bash 
BASE_DIR=$(cd $(dirname $0); pwd -L)

source $(cd $(dirname $0); pwd -L)/common.sh

 display_usage() { 
	echo "
Usage:
    $(basename "$0") <path> [--help or -h]

Description:
    Generates XML labelling per card jpg

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

for path in $(ls "$folder"/*.jpg)
do 
    filename=$(echo $path | awk -F "/" '{print $NF}')
    full_path=$(pwd)/$path
    width=$(identify -format '%w' $path)
    height=$(identify -format '%h' $path)
    normalized_card_name=$(echo $folder | awk -F "/" '{print $NF}')
    xml_filename=$(echo $path | awk -F "." '{print $1".xml"}')
    cat $BASE_DIR/xml_template.xml | sed 's#FOLDER_NAME#'$folder'#g'| sed s/FILE_NAME/"$filename"/g | sed 's#PATH#'$full_path'#g' | sed s/WIDTH/"$width"/g | sed s/HEIGHT/"$height"/g | sed 's#LABEL_NAME#'$normalized_card_name'#g' > $xml_filename
done