import torch
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
from torch.utils.data import DataLoader, random_split
import time
import os
import json
import matplotlib.pyplot as plt
from model import create_modelFaceNet
from face_dataset_loader import DataLoaders

class MobileFaceLoss(nn.Module):
    def __init__(self,num_classes,embedding_size=128,scale=30.0,margin=0.35):
        super(MobileFaceLoss,self).__init__()
        self.embedding_size=embedding_size
        self.num_classes=num_classes
        self.scale=scale
        self.margin=margin

        self.classifier=nn.Linear(embedding_size,num_classes,bias=False)
        nn.init.xavier_uniform_(self.classifier.weight)

    def forward(self,embeddings,labels):
        embedding_norms=F.normalize(embeddings,p=2,dim=1)
        weight_norm=F.normalize(self.classifier.weight,p=2,dim=1)

        cosine=F.linear(embedding_norms,weight_norm)

        one_hot=torch.zeros_like(cosine)
        one_hot.scatter_(1,labels.view(-1,1),1.0)

        cosine_margin=cosine-one_hot*self.margin

        logits=cosine_margin*self.scale

        loss=F.cross_entropy(logits,labels)
        return loss ,logits
    
class MobileTrainer:
    def __init__(self,model, train_loader,val_loader,num_classes,class_names,device="cpu"):
        self.device=device
        self.model=model.to(device)
        self.train_loader=train_loader
        self.val_loader=val_loader
        self.num_classes= num_classes
        self.class_names= class_names

        os.makedirs("checkpoints",exist_ok=True)

        self.criterion=MobileFaceLoss(
            num_classes=num_classes,
            embedding_size=model.embedding_size,

        ).to(device)

        self.optimizer = optim.AdamW([
            {'params': self.model.parameters(), 'lr': 0.001, 'weight_decay': 5e-4},
            {'params': self.criterion.parameters(), 'lr': 0.001, 'weight_decay': 5e-4}
        ])

        self.scheduler=optim.lr_scheduler.CosineAnnealingLR(
            self.optimizer,T_max=30,eta_min=1e-6
        )

        self.history={
            'train_loss': [],
            'val_loss': [],
            'train_acc': [],
            'val_acc': [],
            'learning_rate': []
        }

        self.best_val_acc=0.0
        self.start_time=None

    def train_epoch(self,epoch):
        self.model.train()
        self.criterion.train()
        running_loss=0.0
        correct_predictions=0
        total_samples=0

        print(f"\n=== Epoch {epoch + 1} - Training ===")
        epoch_start = time.time()

        for batch_idx ,(images,labels) in enumerate(self.train_loader):
            images=images.to(self.device)
            labels=labels.to (self.device)


            self.optimizer.zero_grad()
            embeddings=self.model(images, return_embedding=True)
            loss,logits=self.criterion(embeddings,labels)

            loss.backward()
                
            torch.nn.utils.clip_grad_norm_(self.model.parameters(), max_norm=1.0)
            torch.nn.utils.clip_grad_norm_(self.criterion.parameters(), max_norm=1.0)
            self.optimizer.step()
                
            running_loss += loss.item()
            _, predicted = torch.max(logits, 1)
            total_samples += labels.size(0)
            correct_predictions += (predicted == labels).sum().item()
                
            if (batch_idx + 1) % 10 == 0 or (batch_idx + 1) == len(self.train_loader):
                batch_acc = 100.0 * (predicted == labels).sum().item() / labels.size(0)
                elapsed = time.time() - epoch_start
                print(f"  Batch [{batch_idx + 1:3d}/{len(self.train_loader):3d}] | "
                        f"Loss: {loss.item():.4f} | "
                        f"Acc: {batch_acc:5.1f}% | "
                        f"Time: {elapsed:5.1f}s")
            
        avg_loss = running_loss / len(self.train_loader)
        accuracy = 100.0 * correct_predictions / total_samples
        epoch_time = time.time() -epoch_start 
        
        print(f"  Train Results: Loss={avg_loss:.4f}, Acc={accuracy:.2f}%, Time={epoch_time:.1f}s")
        
        return avg_loss, accuracy
    
    def validate_epoch(self, epoch):
        """Validate for one epoch"""
        self.model.eval()
        self.criterion.eval()
        
        running_loss = 0.0
        correct_predictions = 0
        total_samples = 0
        
        print(f"=== Epoch {epoch + 1} - Validation ===")
        
        with torch.no_grad():
            for images, labels in self.val_loader:
                images = images.to(self.device)
                labels = labels.to(self.device)
                
                embeddings = self.model(images, return_embedding=True)
                loss, logits = self.criterion(embeddings, labels)
                
                running_loss += loss.item()
                _, predicted = torch.max(logits, 1)
                total_samples += labels.size(0)
                correct_predictions += (predicted == labels).sum().item()
        
        avg_loss = running_loss / len(self.val_loader)
        accuracy = 100.0 * correct_predictions / total_samples
        
        print(f"  Val Results: Loss={avg_loss:.4f}, Acc={accuracy:.2f}%")
        
        return avg_loss, accuracy
    
    def save_checkpoint(self, filename, epoch, val_acc, is_best=False):
        """Save model checkpoint"""
        checkpoint = {
            'epoch': epoch,
            'model_state_dict': self.model.state_dict(),
            'criterion_state_dict': self.criterion.state_dict(),
            'optimizer_state_dict': self.optimizer.state_dict(),
            'scheduler_state_dict': self.scheduler.state_dict(),
            'val_accuracy': val_acc,
            'num_classes': self.num_classes,
            'class_names': self.class_names,
            'embedding_size': self.model.embedding_size,
            'history': self.history
        }
        
        filepath = f'checkpoints/{filename}'
        torch.save(checkpoint, filepath)
        
        if is_best:
            print(f"     New best model saved: {filepath} (Val Acc: {val_acc:.2f}%)")
        else:
            print(f"     Checkpoint saved: {filepath}")
    
    def train(self, num_epochs=30):
        """Complete training process"""
        print("="*70)
        print(" STARTING MOBILE FACE RECOGNITION TRAINING")
        print("="*70)
        
        total_params = sum(p.numel() for p in self.model.parameters())
        trainable_params = sum(p.numel() for p in self.model.parameters() if p.requires_grad)
        
        print(f" Device: {self.device}")
        print(f" Number of people: {self.num_classes}")
        print(f"  Class names: {self.class_names}")
        print(f" Total parameters: {total_params:,}")
        print(f" Trainable parameters: {trainable_params:,}")
        print(f" Training samples: {len(self.train_loader.dataset)}")
        print(f" Validation samples: {len(self.val_loader.dataset)}")
        print(f" Batch size: {self.train_loader.batch_size}")
        print(f" Training epochs: {num_epochs}")
        print("="*70)
        
        self.start_time = time.time()
        
        for epoch in range(num_epochs):
            train_loss, train_acc = self.train_epoch(epoch)
            
            val_loss, val_acc = self.validate_epoch(epoch)
            
            self.scheduler.step()
            current_lr = self.optimizer.param_groups[0]['lr']
            
            self.history['train_loss'].append(train_loss)
            self.history['val_loss'].append(val_loss)
            self.history['train_acc'].append(train_acc)
            self.history['val_acc'].append(val_acc)
            self.history['learning_rate'].append(current_lr)
            
            print(f"Epoch Summary:")
            print(f"   Learning Rate: {current_lr:.6f}")
            print(f"   Train Loss: {train_loss:.4f} | Val Loss: {val_loss:.4f}")
            print(f"   Train Acc:  {train_acc:5.1f}% | Val Acc:  {val_acc:5.1f}%")
            
            if val_acc > self.best_val_acc:
                self.best_val_acc = val_acc
                self.save_checkpoint('best_model.pth', epoch, val_acc, is_best=True)
            
            if (epoch + 1) % 10 == 0:
                self.save_checkpoint(f'checkpoint_epoch_{epoch+1}.pth', epoch, val_acc)
            
            print("-" * 70)
        
        total_time = time.time() - self.start_time
        print("="*70)
        print(" TRAINING COMPLETED!")
        print(f"  Total training time: {total_time/60:.1f} minutes")
        print(f"Best validation accuracy: {self.best_val_acc:.2f}%")
        print("="*70)
        
        self.save_checkpoint('final_model.pth', num_epochs-1, val_acc)
        
        self.create_mobile_model()
        
        self.plot_training_history()
        
        return self.best_val_acc
    
    def create_mobile_model(self):
        """Create and save mobile-optimized model"""
        print("\n Creating mobile-optimized model...")
        
        checkpoint = torch.load(r'checkpoints/best_model.pth', map_location=self.device)
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model.eval()
        
        mobile_model = {
            'model_state_dict': self.model.state_dict(),
            'num_classes': self.num_classes,
            'class_names': self.class_names,
            'embedding_size': self.model.embedding_size,
            'model_config': {
                'input_size': [3, 112, 112],
                'embedding_size': self.model.embedding_size,
                'num_classes': self.num_classes
            }
        }
        
        torch.save(mobile_model, r'checkpoints/mobile_model.pth')
        print("    Mobile model saved: checkpoints/mobile_model.pth")
        
        model_info = {
            'model_name': 'MobileFaceNet',
            'num_classes': self.num_classes,
            'class_names': self.class_names,
            'embedding_size': self.model.embedding_size,
            'input_size': [112, 112, 3],
            'preprocessing': {
                'resize': [112, 112],
                'normalize_mean': [0.5, 0.5, 0.5],
                'normalize_std': [0.5, 0.5, 0.5]
            },
            'performance': {
                'best_val_accuracy': self.best_val_acc,
                'model_size_mb': sum(p.numel() for p in self.model.parameters()) * 4 / (1024 * 1024)
            }
        }
        
        with open(r'checkpoints/model_info.json', 'w') as f:
            json.dump(model_info, f, indent=2)
        
        print("     Model info saved: checkpoints/model_info.json")
    
    def plot_training_history(self):
        """Plot and save training curves"""
        if len(self.history['train_loss']) == 0:
            return
        
        print("\nGenerating training plots...")
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(12, 8))
        fig.suptitle('Mobile Face Recognition Training History', fontsize=16)
        
        epochs = range(1, len(self.history['train_loss']) + 1)
        
        ax1.plot(epochs, self.history['train_loss'], 'b-', label='Training Loss', linewidth=2)
        ax1.plot(epochs, self.history['val_loss'], 'r-', label='Validation Loss', linewidth=2)
        ax1.set_title('Loss Curves')
        ax1.set_xlabel('Epoch')
        ax1.set_ylabel('Loss')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        ax2.plot(epochs, self.history['train_acc'], 'b-', label='Training Acc', linewidth=2)
        ax2.plot(epochs, self.history['val_acc'], 'r-', label='Validation Acc', linewidth=2)
        ax2.set_title('Accuracy Curves')
        ax2.set_xlabel('Epoch')
        ax2.set_ylabel('Accuracy (%)')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        ax3.plot(epochs, self.history['learning_rate'], 'g-', linewidth=2)
        ax3.set_title('Learning Rate Schedule')
        ax3.set_xlabel('Epoch')
        ax3.set_ylabel('Learning Rate')
        ax3.set_yscale('log')
        ax3.grid(True, alpha=0.3)
        
        ax4.axis('off')
        summary_text = f"""
         Mobile Face Recognition Model
        
         Best Validation Accuracy: {self.best_val_acc:.2f}%
         Number of People: {self.num_classes}
         Model Parameters: {sum(p.numel() for p in self.model.parameters()):,}
         Estimated Size: {sum(p.numel() for p in self.model.parameters()) * 4 / (1024 * 1024):.1f} MB
        
         Dataset Statistics:
        • Training Samples: {len(self.train_loader.dataset)}
        • Validation Samples: {len(self.val_loader.dataset)}
        • Batch Size: {self.train_loader.batch_size}
        
         Training Performance:
        • Final Train Acc: {self.history['train_acc'][-1]:.2f}%
        • Final Val Acc: {self.history['val_acc'][-1]:.2f}%
        • Total Time: {(time.time() - self.start_time)/60:.1f} min
        """
        ax4.text(0.1, 0.9, summary_text, fontsize=10, verticalalignment='top', 
                transform=ax4.transAxes, family='monospace')
        
        plt.tight_layout()
        plt.savefig(r'checkpoints/training_history.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        print("     Training plots saved: checkpoints/training_history.png")

def main():
    """
    Main training function that integrates with your existing pipeline
    """
    print("="*70)
    print(" MOBILE FACE RECOGNITION TRAINING PIPELINE")
    print("="*70)
    
    processed_faces_dir = "ML/data/processed_faces"
    if not os.path.exists(processed_faces_dir):
        print(" ERROR: Processed faces directory not found!")
        print(f"Expected path: {processed_faces_dir}")
        print("\n Please run preProcess.py first to detect and crop faces.")
        print("Steps:")
        print("1. Put raw images in ML/data/[person_name]/ folders")
        print("2. Run preProcess.py to detect and crop faces")
        print("3. Run this script to train the model")
        return
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f" Using device: {device}")
    
    try:
        print("\n Loading dataset...")
        data_loader_obj = DataLoaders()
        train_loader, dataset, class_names = data_loader_obj.dataLoader()
        
        num_classes = len(class_names)
        print(f" Dataset loaded successfully!")
        print(f"    Number of people: {num_classes}")
        print(f"    People names: {class_names}")
        print(f"   Total images: {len(dataset)}")
        
        train_size = int(0.8 * len(dataset))
        val_size = len(dataset) - train_size
        train_dataset, val_dataset = random_split(dataset, [train_size, val_size])

        val_transform = transforms.Compose([
                    transforms.Resize((112, 112)),
                    transforms.ToTensor(),
                    ransforms.Normalize([0.5,0.5,0.5], [0.5,0.5,0.5])
        ])
        
        train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True, num_workers=0)
        val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False, num_workers=0)
        
        print(f"    Training samples: {len(train_dataset)}")
        print(f"    Validation samples: {len(val_dataset)}")
        
        print(f"\n Creating MobileFaceNet model...")
        model = create_modelFaceNet(embedding_size=128, num_classes=num_classes)
        print(f" Model created successfully!")
        
        trainer = MobileTrainer(
            model=model,
            train_loader=train_loader,
            val_loader=val_loader,
            num_classes=num_classes,
            class_names=class_names,
            device=device
        )
        
        best_accuracy = trainer.train(num_epochs=30)
        
        print(f"\n Training completed successfully!")
        print(f" Best validation accuracy: {best_accuracy:.2f}%")
        print(f"Models saved in 'checkpoints/' directory")
        print(f" Ready for mobile deployment!")
        
    except Exception as e:
        print(f" ERROR during training: {e}")
        import traceback
        traceback.print_exc()
        print("\ Troubleshooting:")
        print("1. Make sure preProcess.py has been run successfully")
        print("2. Check that face images exist in processed_faces directory")
        print("3. Verify that PyTorch is installed correctly")

if __name__ == "__main__":
    main()