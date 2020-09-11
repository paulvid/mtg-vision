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
    $(basename "$0") [--help or -h]

Description:
    Generates all needed for example card to train
"

}

# check whether user had supplied -h or --help . If yes display usage
if [[ ($1 == "--help") || $1 == "-h" ]]; then
    display_usage
    exit 0
fi

# Check the numbers of arguments
if [ $# -gt 0 ]; then
    echo "Too many arguments!" >&2
    display_usage
    exit 1
fi

# Exporting variables
card_name="$1"
export_vars

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Starting to prepare card data ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""
echo "⏱  $(date +%H%Mhrs)"
echo ""

normalized_card_name="urzalordhighartificer"
log_file="$BASE_DIR/logs/$normalized_card_name-$(date '+%Y%m%d_%H%M%S').log"


# 1. Download DB
card_db_file="$BASE_DIR/cards/card_db.json"
if [[ ! -f "$card_db_file" ]]; then
    nohup $BASE_DIR/download_card_db.sh >> $log_file 2>&1 &
    sleep 2
    wait_for_process "download_card_db" "card db download"
else
    echo "${ALREADY_DONE} card db already downloaded"
fi

# 2. Copies card images
rm -rf "$BASE_DIR/cards/$normalized_card_name" > /dev/null 2>&1
mkdir "$BASE_DIR/cards/$normalized_card_name"
cp $BASE_DIR/example_card/* $BASE_DIR/cards/$normalized_card_name/
echo "${CHECK_MARK} card example copied"

# 4. Splitting data
nohup $BASE_DIR/split_card_data.sh $BASE_DIR/cards/$normalized_card_name >> $log_file 2>&1 &
sleep 2
wait_for_process "$BASE_DIR/split_card_data.sh" "card data split"

# 5. Generating csv labels
python3 xml_to_csv.py -i $BASE_DIR/cards/$normalized_card_name/train -o $BASE_DIR/cards/$normalized_card_name/train_labels.csv >> $log_file 2>&1
python3 xml_to_csv.py -i $BASE_DIR/cards/$normalized_card_name/test -o $BASE_DIR/cards/$normalized_card_name/test_labels.csv >> $log_file 2>&1
printf "\r${CHECK_MARK} csv label generation completed                                 "
echo ""


# 6. Augmenting dataset
nohup $BASE_DIR/transform_images.sh $normalized_card_name >> $log_file 2>&1 &
wait_for_process "$BASE_DIR/transform_images.sh" "data augmentation"

# 7. Generating tf records
nohup $BASE_DIR/generate_tfrecords.sh $normalized_card_name >> $log_file 2>&1 &
wait_for_process "$BASE_DIR/transform_images.sh" "tf records augmentation"


echo ""
echo "⏱  $(date +%H%Mhrs)"
echo ""
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Finished to prepare card data ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
