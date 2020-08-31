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

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Starting to prepare card data ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""
echo "⏱  $(date +%H%Mhrs)"
echo ""

normalized_card_name=$(echo "$card_name" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
log_file="$normalized_card_name-$(date '+%Y%m%d_%H%M%S').log"


# 1. Download DB
card_db_file="$BASE_DIR/cards/card_db.json"
if [[ ! -f "$card_db_file" ]]; then
    nohup $BASE_DIR/download_card_db.sh >> $log_file 2>&1 &
    sleep 2
    wait_for_process "download_card_db" "card db download"
else
    echo "${ALREADY_DONE} card db already downloaded"
fi

# Checking card exists
oracle_id=$(cat $BASE_DIR/cards/card_db.json | jq -r '.[] | select(.name=="'"$card_name"'")' | jq -r .oracle_id | head -1)
if [ ${#oracle_id} -le 0 ]
then
    handle_exception 1 "card exists check" "card with name  $card_name does not exist!  "
fi

# 2. Dowloading card


nohup $BASE_DIR/download_card_by_name.sh "$card_name" >> $log_file 2>&1 &
sleep 2
wait_for_process "$BASE_DIR/download_card_by_name.sh" "card images download"

# 3. Generate xml label
nohup $BASE_DIR/label_images.sh $BASE_DIR/cards/$normalized_card_name >> $log_file 2>&1 &
sleep 2
wait_for_process "$BASE_DIR/label_images.sh" "label generation"

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
