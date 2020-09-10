checkpoint=$1


python3 export_inference_graph.py --input_type image_tensor --pipeline_config_path training/ssd_inception_v2_coco.config  --trained_checkpoint_prefix training/model.ckpt-$checkpoint --output_directory trained-inference-graphs/output_inference_graph_v1


python3 tensorflow/models/research/object_detection/export_tflite_ssd_graph.py --input_type=image_tensor --input_shape={"image_tensor":[1,600,600,3]} --pipeline_config_path=trained-inference-graphs/output_inference_graph_v1/pipeline.config --trained_checkpoint_prefix=trained-inference-graphs/output_inference_graph_v1/model.ckpt --output_directory=trainedTFLite --add_postprocessing_op=true --max_detections=10

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
  --allow_custom_ops