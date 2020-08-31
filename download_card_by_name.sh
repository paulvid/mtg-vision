BASE_DIR=$(cd $(dirname $0); pwd -L)


card_name=$1


normalized_card_name=$(echo "$card_name" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
rm -rf "$BASE_DIR/cards/$normalized_card_name" > /dev/null 2>&1
mkdir "$BASE_DIR/cards/$normalized_card_name"


for url in $(cat $BASE_DIR/cards/card_db.json | jq -r '.[] | select(.name=="'"$card_name"'")' | jq -r .image_uris.large)
do
    wget --quiet -P $BASE_DIR/cards/$normalized_card_name/ $url
    orig_filename=$(echo $url | awk -F "/" '{print $NF}')
    new_filename=$(echo $orig_filename | awk -F "?" '{print $1}')
    mv "$BASE_DIR/cards/$normalized_card_name/$orig_filename" "$BASE_DIR/cards/$normalized_card_name/$new_filename"
    sleep 5 # being nice to the scryfall apis
done

