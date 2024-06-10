import os
from PIL import Image

def resize_image_pair(before_image_path, after_image_path, output_directory):
    # Создаём выходную директорию, если она не существует
    os.makedirs(output_directory, exist_ok=True)
    
    # Открываем изображения
    with Image.open(before_image_path) as img_before, Image.open(after_image_path) as img_after:
        # Определяем минимальные размеры изображений
        min_width = min(img_before.width, img_after.width)
        min_height = min(img_before.height, img_after.height)

        # Выравниваем размеры изображений
        img_before_resized = img_before.resize((min_width, min_height))
        img_after_resized = img_after.resize((min_width, min_height))

        # Определяем базовые имена файлов без пути
        before_base_name = os.path.basename(before_image_path)
        after_base_name = os.path.basename(after_image_path)

        # Определяем новые пути для сохранения выровненных изображений
        output_before_path = os.path.join(output_directory, before_base_name)
        output_after_path = os.path.join(output_directory, after_base_name)

        # Сохраняем выровненные изображения в новую директорию
        img_before_resized.save(output_before_path)
        img_after_resized.save(output_after_path)

def resize_image_pairs(before_directory, after_directory, output_directory):
    # Получаем список файлов в директории с before_images
    before_files = os.listdir(before_directory)
    # Получаем список файлов в директории с after_images
    after_files = os.listdir(after_directory)

    # Проходимся по файлам из before_images
    for before_filename in before_files:
        # Получаем путь к соответствующему файлу в after_images
        matching_after_filename = next((after_filename for after_filename in after_files if after_filename.startswith(before_filename[0])), None)
        if matching_after_filename:
            # Выравниваем пару изображений
            resize_image_pair(os.path.join(before_directory, before_filename), os.path.join(after_directory, matching_after_filename), output_directory)

# Укажите пути к директориям с изображениями
before_images_directory = "before_images"
after_images_directory = "after_images"
output_images_directory = "output_images"

resize_image_pairs(before_images_directory, after_images_directory, output_images_directory)