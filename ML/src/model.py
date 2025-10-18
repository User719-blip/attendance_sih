import torch
import torch.nn as nn
import torch.nn.functional as F

class ConvBlock(nn.Module):
    def __init__(self, in_channels,out_channels,kernel_size,stride, padding , groups =1):
        super(ConvBlock,self).__init__()
        self.conv=nn.Conv2d(
            in_channels=in_channels,
            out_channels=out_channels,
            kernel_size=kernel_size,
            stride=stride,
            padding=padding,
            groups=groups,
            bias=False
        )
        self.bn=nn.BatchNorm2d(out_channels)
        self.prelu = nn.PReLU(out_channels)


    def forward(self,x):
        x=self.conv(x)
        x=self.bn(x)
        x=self.prelu(x)
        return x 
class DepthWiseSeperableBlock(nn.Module):
    def __init__(self,in_channels,out_channels,stride):
        super(DepthWiseSeperableBlock,self).__init__()
        self.depthwise=ConvBlock(
            in_channels=in_channels,
            out_channels=in_channels,
            kernel_size=3,
            stride=stride,
            padding=1,
            groups=in_channels
        )
        self.pointwise=ConvBlock(
            in_channels=in_channels,
            out_channels=out_channels,
            kernel_size=1,
            stride=1,
            padding=0
        )
    def forward(self,x):
        x=self.depthwise(x)
        x=self.pointwise(x)
        return x
class MobileFaceNet(nn.Module):
    def __init__(self,embedding_size=128,num_classes=None):
        super(MobileFaceNet,self).__init__()
        self.embedding_size=embedding_size  
        self.num_classes=num_classes

        self.conv1=ConvBlock(
            in_channels=3,
            out_channels=64,
            kernel_size=3,
            stride=2,
            padding=1
        )
        self.dw1=DepthWiseSeperableBlock(64,64,stride=1)
        self.conv2=DepthWiseSeperableBlock(64,128,stride=2)
        self.conv3=DepthWiseSeperableBlock(128,128,stride=1)
        self.conv4=DepthWiseSeperableBlock(128,256,stride=2)
        self.conv5=DepthWiseSeperableBlock(256,256,stride=1)
        self.conv6=DepthWiseSeperableBlock(256,512,stride=2)

        self.conv7=nn.Conv2d(
            in_channels=512,
            out_channels=embedding_size,
            kernel_size=7,
            stride=1,
            padding=0,
            bias=False
        )
        self.bn = nn.BatchNorm2d(embedding_size)
        if num_classes is not None:
            self.classifier = nn.Linear(embedding_size, num_classes)
        else:
            self.classifier = None

    def forward(self,x,return_embedding=True):
        batch_size=x.size(0)
        x=self.conv1(x)
        x=self.dw1(x)
        x=self.conv2(x)
        x=self.conv3(x)
        x=self.conv4(x)
        x=self.conv5(x)
        x=self.conv6(x)
        x=self.conv7(x)

        x=self.bn(x)
        x=x.view(batch_size,-1)

        embeddings=F.normalize(x,p=2,dim=1)

        if return_embedding or self.classifier is None:
            return embeddings
        else:
            logits=self.classifier(embeddings)
            return logits
    def get_model_size(self):
        
        total_params = sum(p.numel() for p in self.parameters())
        trainable_params = sum(p.numel() for p in self.parameters() if p.requires_grad)
        
        model_size_mb = (total_params * 4) / (1024 * 1024)
        
        print(f"   Model Statistics:")
        print(f"   Total parameters: {total_params:,}")
        print(f"   Trainable parameters: {trainable_params:,}")
        print(f"   Estimated size: {model_size_mb:.2f} MB")
        
        return total_params, trainable_params, model_size_mb
def create_modelFaceNet(embedding_size=128,num_classes=None):
    model =MobileFaceNet(embedding_size=embedding_size,num_classes=num_classes)
    model.get_model_size()
    return model

    
if __name__=="__main__":
    print("="*15,'Executed',"="*15)



