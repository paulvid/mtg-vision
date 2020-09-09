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
checkpoint="$1"
export_vars

log_file="$BASE_DIR/logs/$checkpoint-$(date '+%Y%m%d_%H%M%S').log"

PYTHONPATH=''
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/slim
export PYTHONPATH=$PYTHONPATH:$BASE_DIR/tensorflow/models/research/object_detection
export PATH=$PATH:~/.local/bin 

rm -rf trained-inference-graphs/* > /dev/null 2>&1
rm -rf trainedModels/* > /dev/null 2>&1
rm -rf trainedTFLite/* > /dev/null 2>&1

python3 export_inference_graph.py --input_type image_tensor \
--pipeline_config_path training/ssd_inception_v2_coco.config \
--trained_checkpoint_prefix training/model.ckpt-$checkpoint \
--output_directory trained-inference-graphs/output_inference_graph_v1 >> $log_file 2>&1 
 

python3 tensorflow/models/research/object_detection/export_tflite_ssd_graph.py \
    --input_type=image_tensor \
    --input_shape={"image_tensor":[1,600,600,3]} \
    --pipeline_config_path=trained-inference-graphs/output_inference_graph_v1/pipeline.config \
    --trained_checkpoint_prefix=trained-inference-graphs/output_inference_graph_v1/model.ckpt \
    --output_directory=trainedTFLite \
    --add_postprocessing_op=true \
    --max_detections=10 >> $log_file 2>&1 


toco --output_file=trainedModels/LogoObjD.tflite \
  --graph_def_file=trainedTFLite/tflite_graph.pb \
  --input_format=TENSORFLOW_GRAPHDEF \
  --inference_input_type=QUANTIZED_UINT8 \
  --inference_type=QUANTIZED_UINT8 \
  --input_arrays=normalized_input_image_tensor \
  --input_shape=1,300,300,3 \
  --input_data_type=QUANTIZED_UINT8 \
  --output_format=TFLITE \
  --output_arrays='TFLite_Detection_PostProcess','TFLite_Detection_PostProcess:1','TFLite_Detection_PostProcess:2','TFLite_Detection_PostProcess:3'  \
  --mean_values=128 \
  --std_dev_values=128 \
  --default_ranges_min=0 \
  --default_ranges_max=300 \
  --allow_custom_ops  >> $log_file 2>&1 


echo "Package almost complete:"
echo "1. go to trainedModels/ and run edgetpu_compiler LogoObjD.tflite"
echo "2. scp LogoObjD_edgetpu.tflite mendel@10.0.0.58:~/mtg/"
echo "3. edgetpu_detect_server --model LogoObjD_edgetpu.tflite --label label.txt --threshold=0.51"
