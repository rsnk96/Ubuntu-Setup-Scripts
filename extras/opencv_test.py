import cv2
import pathlib

image_name = "github.png"
video_name = "test.mp4"
print(cv2.getBuildInformation())


current_dir = str(pathlib.Path(__file__).parent.absolute())

img = cv2.imread(current_dir + "/" + image_name)
if img is not None:
    print("Imread successful!")

cap = cv2.VideoCapture(current_dir + "/" + video_name)
if cap is not None and cap.isOpened():
    print("VideoCapture successful!")
