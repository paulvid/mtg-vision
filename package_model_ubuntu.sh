#!/bin/bash
export BASE_DIR=$(
    cd $(dirname $0)
    pwd -L
)

source $(
    cd $(dirname $0)
    pwd -L
)/common.sh

display_usage() {
    echo "
Usage:
    $(basename "$0") <checkpoint> [--help or -h]

Description:
    Packages model for edge TPU

Arguments:
    checkpoint: model checkpoint
"

}

# check whether user had supplied -h or --help . If yes display usage
if [[ ($1 == "--help") || $1 == "-h" ]]; then
    display_usage
    exit 0
fi

# Check the numbers of arguments
if [ $# -lt 1 ]; then
    echo "Not enough arguments!" >&2
    display_usage
    exit 1
fi

if [ $# -gt 1 ]; then
    echo "Too many arguments!" >&2
    display_usage
    exit 1
fi

# Exporting variables
checkpoint="$1"
export_vars

log_file="$BASE_DIR/logs/$checkpoint-$(date '+%Y%m%d_%H%M%S').log"
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Starting to package model ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""
echo "⏱  $(date +%H%Mhrs)"
echo ""


rm -rf trained-inference-graphs/* > /dev/null 2>&1
rm -rf trainedModels/* > /dev/null 2>&1
rm -rf trainedTFLite/* > /dev/null 2>&1

nohup $BASE_DIR/create_tf_lite_model.sh $checkpoint >> $log_file 2>&1 &
wait_for_process "create_tf_lite_model.sh" "creating tf lite"



edgetpu_compiler $BASE_DIR/trainedModels/LogoObjD.tflite >> $log_file 2>&1 
printf "\r${CHECK_MARK} model compiled for edge tpu"
echo ""
 
echo "${CHECK_MARK} Package completed; upload the LogoObjD_edgetpu.tflite to your coral TPU and run your model: edgetpu_detect_server --model mtg/LogoObjD_edgetpu.tflite --label mtg/label.txt --threshold=0.51"

echo ""
echo "⏱  $(date +%H%Mhrs)"
echo ""
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Finished to package model ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"