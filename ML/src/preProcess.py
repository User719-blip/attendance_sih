import cv2
import mediapipe as mp
import os 

mp_face_detection=mp.solutions.face_detection
mp_drawing=mp.solutions.drawing_utils

input_dir="ML\\data"
output_dir="ML\\data\\processed_faces"



with mp_face_detection.FaceDetection(model_selection=0,min_detection_confidence=0.5) as face_detection:
    for person in os.listdir(input_dir):
        person_dir=os.path.join(input_dir,person)
        save_dir=os.path.join(output_dir,person)
        os.makedirs(save_dir,exist_ok=True)
        
        for img in os.listdir(person_dir):
            img_path=os.path.join(person_dir,img)
            if not os.path.isfile(img_path) or not img.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff')):
                continue
            image=cv2.imread(img_path)

            if image is None:
                print(f"[ERROR] Could not read image: {img_path}")

            results=face_detection.process(cv2.cvtColor(image,cv2.COLOR_BGR2RGB))

            if results.detections:
                for i,detection in enumerate(results.detections):
                    bboxC=detection.location_data.relative_bounding_box
                    h,w,_=image.shape
                    x=int(bboxC.xmin*w)
                    y=int(bboxC.ymin*h)
                    w_box=int(bboxC.width*w)
                    h_box=int(bboxC.height*h)

                    margin = 0.2  
                    x1 = max(0, x - int(w_box * margin))
                    y1 = max(0, y - int(h_box * margin))
                    x2 = min(w, x + w_box + int(w_box * margin))
                    y2 = min(h, y + h_box + int(h_box * margin))

                    # Crop with margin
                    face = image[y1:y2, x1:x2]
                    if face.size == 0:
                        print(f"[WARNING] Empty face crop for {img_path}, detection {i}")
                        continue

                    # Resize to 112×112
                    face = cv2.resize(face, (112, 112))

                    save_path=os.path.join(save_dir,f"{i}_{img}")
                    cv2.imwrite(save_path,face)
                    print(f"saved {save_path}")
