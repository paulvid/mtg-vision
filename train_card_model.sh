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
    $(basename "$0") <card_name> [--help or -h]

Description:
    Generates all needed for card to train

Arguments:
    card_name: Name of your card
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
card_name="$1"
export_vars

# 1. Download DB
card_db_file="$BASE_DIR/cards/card_db.json"
if [[ ! -f "$card_db_file" ]]; then
    handle_exception 1 "card db verification" "card db not found!"
fi
normalized_card_name=$(echo "$card_name" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')

cat $BASE_DIR/label_map_template.pbtxt | sed s/REPLACE_LABEL/$normalized_card_name/g > $BASE_DIR/label_map.pbtxt
cat $BASE_DIR/ssd_inception_v2_coco_template.config | sed s/REPLACE_LABEL/$normalized_card_name/g > $BASE_DIR/training/ssd_inception_v2_coco.config


PYTHONPATH=''
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/slim
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/object_detection
export PATH=$PATH:~/.local/bin 

# 2. Dowloading card
python3 $BASE_DIR/train.py --logtostderr --train_dir=training/ --pipeline_config_path=training/ssd_inception_v2_coco.config

