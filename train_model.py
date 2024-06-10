import os
import numpy as np
import cv2
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import transforms

# Загрузка данных
def load_image_pairs(output_images_dir):
    image_pairs = []
    for file_name in os.listdir(output_images_dir):
        if file_name.endswith('.tif'):
            before_path = os.path.join(output_images_dir, file_name[:-5] + '0.tif')
            after_path = os.path.join(output_images_dir, file_name[:-5] + '1.tif')
            if os.path.exists(before_path):
                image_pairs.append((before_path, after_path))
    return image_pairs

output_images_dir = '../output_images'
image_pairs = load_image_pairs(output_images_dir)

# Определение нейронной сети
class SegmentationNet(nn.Module):
    def __init__(self):
        super(SegmentationNet, self).__init__()
        # Изменяем количество входных каналов на 256
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

# Подготовка данных для обучения
class CustomDataset(torch.utils.data.Dataset):
    def __init__(self, image_pairs, transform=None):
        self.image_pairs = image_pairs
        self.transform = transform

    def __len__(self):
        return len(self.image_pairs)

    def __getitem__(self, idx):
        before_path, after_path = self.image_pairs[idx]
        img_before = cv2.imread(before_path)
        img_after = cv2.imread(after_path)
        img_before = cv2.cvtColor(img_before, cv2.COLOR_BGR2RGB)
        img_after = cv2.cvtColor(img_after, cv2.COLOR_BGR2RGB)
        combined = np.concatenate((img_before, img_after), axis=2)  # Уберем конкатенацию
        if self.transform:
            combined = self.transform(combined)
        return combined.permute(2, 0, 1)  # Изменим порядок размерностей на (каналы, высота, ширина)
        
transform = transforms.Compose([
    transforms.ToTensor(),
    transforms.Resize((256, 256))
])

dataset = CustomDataset(image_pairs, transform)
train_loader = torch.utils.data.DataLoader(dataset, batch_size=8, shuffle=True)

# Обучение модели
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = SegmentationNet().to(device)
criterion = nn.MSELoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Генерация целевых значений (пользовательская обратная связь)
def generate_targets(batch_size):
    # Здесь можно реализовать сбор пользовательской обратной связи
    # Для примера используем случайные значения
    radii = np.random.randint(2, 10, size=(batch_size, 1))
    max_pix = np.random.randint(100, 1000, size=(batch_size, 1))
    return torch.tensor(np.hstack((radii, max_pix)), dtype=torch.float32).to(device)

num_epochs = 10
for epoch in range(num_epochs):
    model.train()
    running_loss = 0.0
    for i, inputs in enumerate(train_loader):
        inputs = inputs.to(device)
        targets = generate_targets(inputs.size(0))

        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, targets)
        loss.backward()
        optimizer.step()

        running_loss += loss.item()
        if i % 10 == 9:
            print(f'Epoch [{epoch+1}/{num_epochs}], Step [{i+1}/{len(train_loader)}], Loss: {running_loss/10:.4f}')
            running_loss = 0.0
# Сохранение модели
torch.save(model.state_dict(), 'segmentation_net.pth')
