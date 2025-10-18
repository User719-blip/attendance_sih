"

import torch
import torch.nn.functional as F
import cv2
import numpy as np
from PIL import Image
import os
import time
import mediapipe as mp
from model import create_modelFaceNet

class FaceRecognitionInference:
    def __init__(self, model_path='checkpoints/mobile_model.pth', threshold=0.6):
        self.device = torch.device('cpu')
        self.threshold = threshold
        self.face_database = {}
        
        # Load model
        checkpoint = torch.load(model_path, map_location=self.device)
        self.embedding_size = checkpoint['embedding_size']
        self.class_names = checkpoint['class_names']
        
        self.model = create_modelFaceNet(embedding_size=self.embedding_size, num_classes=None)
        
        # Filter out classifier weights for inference
        model_state = checkpoint['model_state_dict']
        filtered_state = {k: v for k, v in model_state.items() 
                         if not k.startswith('classifier')}
        self.model.load_state_dict(filtered_state)
        self.model.to(self.device)
        self.model.eval()
        
        # Initialize face detection
        self.mp_face_detection = mp.solutions.face_detection
        self.face_detection = self.mp_face_detection.FaceDetection(
            model_selection=0, min_detection_confidence=0.5
        )
        
        print(f"Model loaded - Embedding size: {self.embedding_size}")
        print(f"Trained on: {self.class_names}")
    
    def detect_faces(self, image):
        """Detect faces and return bounding boxes"""
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = self.face_detection.process(rgb_image)
        
        faces = []
        if results.detections:
            h, w, _ = image.shape
            for detection in results.detections:
                bbox = detection.location_data.relative_bounding_box
                x = int(bbox.xmin * w)
                y = int(bbox.ymin * h)
                width = int(bbox.width * w)
                height = int(bbox.height * h)
                
                # Ensure valid coordinates
                x = max(0, min(x, w-1))
                y = max(0, min(y, h-1))
                width = max(1, min(width, w-x))
                height = max(1, min(height, h-y))
                
                if width >= 30 and height >= 30:
                    faces.append((x, y, width, height))
        
        return faces
    
    def preprocess_face(self, image, bbox):
        """Preprocess face for model input"""
        x, y, w, h = bbox
        face = image[y:y+h, x:x+w]
        
        # Convert to PIL and resize
        face_pil = Image.fromarray(cv2.cvtColor(face, cv2.COLOR_BGR2RGB))
        face_pil = face_pil.resize((112, 112), Image.BILINEAR)
        
        # Convert to tensor and normalize
        face_array = np.array(face_pil, dtype=np.float32)
        face_tensor = torch.from_numpy(face_array).permute(2, 0, 1) / 255.0
        face_tensor = (face_tensor - 0.5) / 0.5  # Normalize to [-1, 1]
        
        return face_tensor.unsqueeze(0)
    
    @torch.no_grad()
    def get_embedding(self, image, bbox):
        """Extract face embedding"""
        input_tensor = self.preprocess_face(image, bbox)
        embedding = self.model(input_tensor, return_embedding=True)
        embedding = F.normalize(embedding, p=2, dim=1)
        return embedding.cpu().numpy()[0]
    
    def build_database(self, database_path):
        """Build face database from processed faces directory"""
        if not os.path.exists(database_path):
            print(f"Database path not found: {database_path}")
            return
        
        print("Building face database...")
        for person_name in os.listdir(database_path):
            person_dir = os.path.join(database_path, person_name)
            if os.path.isdir(person_dir):
                embeddings = []
                
                for img_file in os.listdir(person_dir):
                    if img_file.lower().endswith(('.jpg', '.png', '.jpeg')):
                        img_path = os.path.join(person_dir, img_file)
                        image = cv2.imread(img_path)
                        
                        if image is not None:
                            # Use entire image as face (since it's already cropped)
                            h, w = image.shape[:2]
                            bbox = (0, 0, w, h)
                            embedding = self.get_embedding(image, bbox)
                            embeddings.append(embedding)
                
                if embeddings:
                    # Average embeddings for this person
                    avg_embedding = np.mean(embeddings, axis=0)
                    avg_embedding = avg_embedding / np.linalg.norm(avg_embedding)
                    self.face_database[person_name] = avg_embedding
                    print(f"Added {person_name}: {len(embeddings)} images")
        
        print(f"Database built with {len(self.face_database)} people")
    
    def identify_person(self, image, face_bbox):
        """Identify person from face database"""
        if len(self.face_database) == 0:
            return "Unknown", 0.0
        
        # Get embedding for detected face
        face_embedding = self.get_embedding(image, face_bbox)
        
        # Compare with database
        best_match = "Unknown"
        best_score = 0.0
        
        for person_name, db_embedding in self.face_database.items():
            similarity = np.dot(face_embedding, db_embedding)
            if similarity > best_score:
                best_score = similarity
                if similarity >= self.threshold:
                    best_match = person_name
        
        return best_match, best_score
    
    def process_image(self, image_path):
        """Process single image for face recognition"""
        image = cv2.imread(image_path)
        if image is None:
            print(f"Could not load image: {image_path}")
            return
        
        faces = self.detect_faces(image)
        print(f"Detected {len(faces)} faces in {image_path}")
        
        for i, face_bbox in enumerate(faces):
            person, confidence = self.identify_person(image, face_bbox)
            print(f"Face {i+1}: {person} (confidence: {confidence:.3f})")
            
            # Draw bounding box and label
            x, y, w, h = face_bbox
            color = (0, 255, 0) if person != "Unknown" else (0, 0, 255)
            cv2.rectangle(image, (x, y), (x+w, y+h), color, 2)
            cv2.putText(image, f"{person}: {confidence:.2f}", (x, y-10),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        
        return image
    
    def run_webcam(self):
        """Run real-time face recognition on webcam"""
        cap = cv2.VideoCapture(0)
        qit=input("Starting webcam... Press 'q' to quit")
        
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            faces = self.detect_faces(frame)
            
            for face_bbox in faces:
                person, confidence = self.identify_person(frame, face_bbox)
                
                x, y, w, h = face_bbox
                color = (0, 255, 0) if person != "Unknown" else (0, 0, 255)
                cv2.rectangle(frame, (x, y), (x+w, y+h), color, 2)
                cv2.putText(frame, f"{person}: {confidence:.2f}", (x, y-10),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
            
            cv2.imshow('Face Recognition', frame)
            
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        
        cap.release()
        cv2.destroyAllWindows()

def main():
    # Initialize inference system
    recognizer = FaceRecognitionInference(
        model_path='checkpoints/mobile_model.pth',
        threshold=0.6
    )
    
    # Build database from processed faces
    recognizer.build_database('ML/data/processed_faces')
    
    # Choose what to do
    print("\nChoose option:")
    print("1. Process single image")
    print("2. Run webcam recognition")
    print("3. exit program")
    while True:
        choice = input("Enter choice (1 or 2): ")
        if choice == '1':
            img_path = input("Enter image path: ")
            result_image = recognizer.process_image(img_path)
            if result_image is not None:
                cv2.imshow('Result', result_image)
                cv2.waitKey(0)
                cv2.destroyAllWindows()
        
        elif choice == '2':
            recognizer.run_webcam()
        elif choice=="3":
            break
        
        else:
            print("Invalid choice")

if __name__ == "__main__":
    main()