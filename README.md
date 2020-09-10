

# MTG Card Identification

This project is based on the work by the Data Jedi Ian Brooks (see [LogoTL repo](https://github.com/BrooksIan/LogoTL)).
Its goal is to identify a magic the gathering card based on its picture.

# Setup

## Pre-Requisites
* jq
* python 3.5
* docker

## Dependencies
```
./install_dependencies.sh
```

## Card Data preparation

```
./prepare_card_for_model.sh "[name_of_your_card]"
```

## Model training
```
./train_card_model.sh "[name_of_your_card]"
```

## Model packaaging
```
./train_card_model.sh [checkpoint_number]
```


# Author & Contributors

**Paul Vidal** - [LinkedIn](https://www.linkedin.com/in/paulvid/)