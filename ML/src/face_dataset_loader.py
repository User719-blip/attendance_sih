import torch
from torchvision import transforms , datasets
from torch.utils.data import DataLoader
import os

transform=transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize([0.5,0.5,0.5],
                         [0.5,0.5,0.5])
])
data_folder="ML\\data\\processed_faces"
if not os.path.exists(data_folder):
    print(f" ERROR: Folder '{data_folder}' not found!")
    print("Please make sure you've run the face detection script first.")
    exit()
dataset=datasets.ImageFolder(
    root=data_folder,
    transform=transform
)
print(f"\n Dataset loaded from '{data_folder}'")

train_loader=DataLoader(
    dataset=dataset,
    batch_size=32,
    shuffle=True,
    num_workers=0,
    pin_memory=True
)
class_name=dataset.classes
num_class=len(class_name)
print(f"\nClass names (first 2): {class_name[:2]}")
