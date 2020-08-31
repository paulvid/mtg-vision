

from PIL import Image
import argparse
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import csv
import tensorflow as tf

from DataAugmentationForObjectDetection.data_aug.data_aug import *
from DataAugmentationForObjectDetection.data_aug.bbox_util import *
import cv2 
import pickle as pkl

#"""
#Define Application Flags
flags = tf.app.flags
# flags.DEFINE_string('img_input_dir', 'cards/0ca233f4-1b7f-4807-ab6e-2b1f5439b3db/train/', 'Path to image director')
# flags.DEFINE_string('image_label_file', 'cards/0ca233f4-1b7f-4807-ab6e-2b1f5439b3db/train_labels.csv', 'Path to the image label CSV file')
# flags.DEFINE_string('numIters', '100', 'Number of iterations for each image')
# flags.DEFINE_string('output_path', 'cards/0ca233f4-1b7f-4807-ab6e-2b1f5439b3db/train_labels_DA.csv', 'Path to output image label CSV file')
# flags.DEFINE_string('label0', '0ca233f4-1b7f-4807-ab6e-2b1f5439b3db', 'Name of class[0] label')
# flags.DEFINE_string('label1', '0ca233f4-1b7f-4807-ab6e-2b1f5439b3db', 'Name of class[1] label')
# flags.DEFINE_string('label2', '0ca233f4-1b7f-4807-ab6e-2b1f5439b3db', 'Name of class[2] label')
                              
FLAGS = flags.FLAGS
#"""

#=============  Method - Write Pickle Files ======================
def writePickleFile(img_input_dir, image_fileName, objectAnnotation, ID, class_name):

  #Prepare to Write Annotations to Pickle File
  img_pickle_dir = img_input_dir + "pickle/"  
  fileName = img_pickle_dir + str(image_fileName).split(".")[0] + "_" + str(ID) + "_" + class_name + ".pkl"
  fileObject = open(fileName, 'wb')
  pkl.dump(objectAnnotation, fileObject)
  print('Pickle File Created @: ' + fileName)
  fileObject.close()
  return fileName
#=============  End of Method - Write Pickle Files ===============    


#=============  Method - createSyntheticImages =================
def createSyntheticImage(img_input_dir, image_fileName, pickleFile, image_id):
  
  imagePath = img_input_dir +'/'+ image_fileName
  
  #Read Original Image
  img = cv2.imread(imagePath)[:,:,::-1]   
  bboxes = pkl.load(open(pickleFile, "rb"))
  #print(bboxes)
              
  #Sequence Multiple Data Augmentation Steps to a new image
  #seq = Sequence([RandomHSV(40, 40, 30), RandomScale(), RandomTranslate(), RandomRotate(10), RandomShear(), RandomResize(640)])
  seq = Sequence([RandomHSV(40, 40, 30), RandomScale(0.3), RandomTranslate(0.3), RandomShear(), Resize(600)])
  img_seq, bboxes_seq = seq(img.copy(), bboxes.copy())
  
  #Save File
  DAImageName = str(image_id) + "_da_"+ image_fileName
  saveDAImagePath =  img_input_dir + "DA/" + DAImageName
  matplotlib.image.imsave(saveDAImagePath, img_seq)
  
  #print('***Data Augmentation ** Synthetic Image Created @ ' + saveDAImagePath) 
  
  return DAImageName, bboxes_seq #Return Object Boundary Boxes
  
#=============  End of Method - createSyntheticImages =================


#=============  Method - writeToCSVOutFile =================
def writeToCSVOutFile(writeRow, writeCode, DA_label_file):
  
  
  with open(DA_label_file, writeCode) as csvOFile:
                writer = csv.writer(csvOFile)
                writer.writerow(writeRow)
                csvOFile.close()
          
#=============  End of Method - writeToCSVOutFile =================


#=============  Method - Main ==============================
def main(_):

  parser = argparse.ArgumentParser(
      description="Sample Image augmenter")
  parser.add_argument("-i",
                      "--inputDir",
                      help="Path to the folder where the input .jpg files are stored",
                      type=str)
  parser.add_argument("-n",
                      "--numIters",
                      help="number of iteration for DA",
                      type=int)
  parser.add_argument("-f",
                      "--imageLabelFile",
                      help="Path to the image label CSV file",
                      type=str)
  parser.add_argument("-o",
                      "--outputPath",
                      help="Path to the out image label CSV file", type=str)
  parser.add_argument("-l",
                      "--label",
                      help="label of your file", type=str)
  args = parser.parse_args()
    
#Define Class Paths 
  label_file= args.imageLabelFile        # default value = annotations/train_labels.csv
  DA_label_file = args.outputPath         # default value = annotations/train_labels_DA.csv
  class_name= args.label                 # default value = Cloudera
  
  #Open CSV Label File
  with open(label_file) as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    for row in csv_reader:
        if line_count == 0:
            #print(f'Column names are {", ".join(row)}')
            line_count += 1
           
            # Output row for DA CSV File
            header_row = ['filename','width','height','class','xmin','ymin','xmax','ymax']
            writeToCSVOutFile(header_row, 'w', args.outputPath)
            
        else:
            #print(f'\t{row[0]} w:{row[1]} h:{row[2]} with object: {row[3]} at  xmin:{row[4]} ymin:{row[5]} xmax:{row[6]} ymax:{row[7]} ')
            line_count += 1
            image_fileName = row[0]
            imageW = row[1]
            imageH = row[2]
            xmin = float(row[4])
            ymin = float(row[5])
            xmax = float(row[6])
            ymax = float(row[7])
            class_name = row[3]
            
            #Write Picke File for Image
            objectAnnotation = np.array([xmin, ymin, xmax, ymax, 0], ndmin=2)
            pickleFile = writePickleFile(args.inputDir, image_fileName, objectAnnotation, line_count, class_name)
            
            #if line_count == 132:
              
              #Write Original Image to CSV File
              #O_row = [image_fileName, imageW, imageH, class_name, int(xmin), int(ymin), int(xmax), int(ymax)]
              #writeToCSVOutFile(O_row, 'a')
                           
              #Create a new syntethic image based on the number of user provided iterations
            for i in range( int(args.numIters) ):
                        
                #Create Syntethic Image and Return FileName and Object Boundaries 
                DAImageName, boundaryBoxes = createSyntheticImage(args.inputDir, image_fileName, pickleFile, i)
                
                #print(boundaryBoxes)
                
                if boundaryBoxes.shape[0] == 1:
                  xminBB = int(boundaryBoxes[0][0])
                  yminBB = int(boundaryBoxes[0][1])
                  xmaxBB = int(boundaryBoxes[0][2])
                  ymaxBB = int(boundaryBoxes[0][3])
                  
                  DA_row = [ DAImageName , imageW, imageH, class_name, xminBB, yminBB, xmaxBB, ymaxBB]
                  writeToCSVOutFile(DA_row, 'a', args.outputPath)
                  
                else:
                  xminBB = int(xmin)
                  yminBB = int(ymin)
                  xmaxBB = int(xmax)
                  ymaxBB = int(ymax)
              
                #print(boundaryBoxes)
              
                # Write Output Row to CSV File
                #DA_row = [ DAImageName , imageW, imageH, class_name, xminBB, yminBB, xmaxBB, ymaxBB]
                #writeToCSVOutFile(DA_row, 'a')
       
            print('***Data Augmentation ** ' + str(args.numIters) + ' Synthetic Images Created For Image ' + image_fileName) 
                                                           
    print('Processed {line_count} images in CSV file: ' + label_file)  
  
    print('Successfully created the Output CSV Label File:{}'.format(args.outputPath))

#=============  End of Method - Main ==============================


if __name__ == '__main__': tf.app.run()
