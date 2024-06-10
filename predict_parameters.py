import os
import sys
import numpy as np
import cv2
import torch
from torchvision import transforms
import torch.nn as nn

# Определение нейронной сети
class SegmentationNet(nn.Module):
    def __init__(self):
        super(SegmentationNet, self).__init__()
        self.conv1 = nn.Conv2d(256, 64, kernel_size=3, padding=1)
        self.conv2 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.conv3 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.fc1 = nn.Linear(256 * 6 * 256, 256)  # Исправлен размер входа для fc1
        self.fc2 = nn.Linear(256, 2)  # Предсказание радиуса и макс. числа пикселей объектов

    def forward(self, x):
        x = torch.relu(self.conv1(x))
        x = torch.relu(self.conv2(x))
        x = torch.relu(self.conv3(x))
        x = x.view(x.size(0), -1)
        x = torch.relu(self.fc1(x))
        x = self.fc2(x)
        return x

# Загрузка модели
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = SegmentationNet().to(device)
model.load_state_dict(torch.load('../segmentation_net.pth', map_location=device))
model.eval()

# Подготовка данных
def load_image(image_path):
    img = cv2.imread(image_path)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    return img

transform = transforms.Compose([
    transforms.ToTensor(),
    transforms.Resize((256, 256))
])

def prepare_input(before_path, after_path):
    img_before = load_image(before_path)
    img_after = load_image(after_path)
    combined = np.concatenate((img_before, img_after), axis=2)
    combined = transform(combined)
    return combined.unsqueeze(0)  # Добавляем размерность для батча

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python predict_parameters.py <before_image_path> <after_image_path>")
        sys.exit(1)

    before_path = sys.argv[1]
    after_path = sys.argv[2]
    input_tensor = prepare_input(before_path, after_path).to(device)

    # Получение предсказания
    with torch.no_grad():
        output = model(input_tensor)
        predicted_radii, predicted_max_pix = output.cpu().numpy()[0]

    print(f'Predicted radius: {predicted_radii}, maxNumberOfPixObj: {predicted_max_pix}')