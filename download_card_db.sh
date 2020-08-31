BASE_DIR=$(cd $(dirname $0); pwd -L)


file=$(curl -s https://api.scryfall.com/bulk-data/all_cards | jq -r .download_uri)
rm -rf $BASE_DIR/cards/card_db.json > /dev/null 2>&1
wget -O $BASE_DIR/cards/card_db.json $(curl -s https://api.scryfall.com/bulk-data/all_cards | jq -r .download_uri)