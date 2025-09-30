import torch
from torchvision import transforms , datasets
from torch.utils.data import DataLoader
import os
class DataLoaders():
    def __init__(self):
        self.dataset=None
        self.num_class=None
        self.class_name=None
        self.data_folder=None
        self.Batch=32
    def dataLoader(self): 
        transform=transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize([0.5,0.5,0.5],
                                [0.5,0.5,0.5]),
        transforms.RandomHorizontalFlip(0.5),
        transforms.RandomRotation(10),
        transforms.ColorJitter(brightness=0.2)
        ])
        self.data_folder="ML\\data\\processed_faces"
        if not os.path.exists(self.data_folder):
            print(f" ERROR: Folder '{self.data_folder}' not found!")
            print("Please make sure you've run the face detection script first.")
            exit()
        self.dataset=datasets.ImageFolder(
            root=self.data_folder,
            transform=transform
        )
        print(f"\n Dataset loaded from '{self.data_folder}'")

        train_loader=DataLoader(
            dataset=self.dataset,
            batch_size=32,
            shuffle=True,
            num_workers=0,
            pin_memory=True
        )
        self.class_name=self.dataset.classes
        self.num_class=len(self.class_name)
        return train_loader ,self.dataset,self.class_name

