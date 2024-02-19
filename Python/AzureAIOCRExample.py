#Based on learn example https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/quickstarts-sdk/client-library?tabs=windows%2Cvisual-studio&pivots=programming-language-python
#Get pip installed (run in elevated)
#python.exe -m pip install --upgrade pip
#pip install --upgrade azure-cognitiveservices-vision-computervision
#pip install pillow

#Get your endpoints setup
#setx AI_SVC_KEY YOURKEY
#setx AI_SVC_ENDPOINT YOURENDPOINT

from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from azure.cognitiveservices.vision.computervision.models import OperationStatusCodes
from azure.cognitiveservices.vision.computervision.models import VisualFeatureTypes
from msrest.authentication import CognitiveServicesCredentials

from array import array
import os
from PIL import Image
import sys
import time

#Authenticate
subscription_key = os.environ["AI_SVC_KEY"]
endpoint = os.environ["AI_SVC_ENDPOINT"]
computervision_client = ComputerVisionClient(endpoint, CognitiveServicesCredentials(subscription_key))


#OCR: Read File using the Read API, extract text - remote
print("===== Read File - remote =====")
# Get an image with text
read_image_url = "https://github.com/johnthebrit/RandomStuff/raw/master/Whiteboards/RAG.png"

# Call API with URL and raw response (allows you to get the operation location)
read_response = computervision_client.read(read_image_url,  raw=True)

# Get the operation location (URL with an ID at the end) from the response
read_operation_location = read_response.headers["Operation-Location"]
# Grab the ID from the URL
operation_id = read_operation_location.split("/")[-1]

# Call the "GET" API and wait for it to retrieve the results
while True:
    read_result = computervision_client.get_read_result(operation_id)
    if read_result.status not in ['notStarted', 'running']:
        break
    time.sleep(1)

# Print the detected text, line by line
if read_result.status == OperationStatusCodes.succeeded:
    for text_result in read_result.analyze_result.read_results:
        for line in text_result.lines:
            print(line.text)
            print(line.bounding_box)
print()