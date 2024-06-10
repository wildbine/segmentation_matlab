# Makefile

.PHONY: all install train predict

# Определение виртуального окружения
VENV = venv

# Все задачи
all: install setenv train

# Установка библиотек
install:
	@echo "Создание виртуального окружения..."
	python -m venv $(VENV)
	@echo "Активируем виртуальное окружение и устанавливаем библиотеки..."
	$(VENV)\Scripts\activate && pip install torch torchvision Pillow numpy opencv-python


# Обучение модели
train:
	@echo "Обучение модели..."
	$(VENV)\Scripts\activate && python size_eq.py && python train_model.py

# Предсказание параметров для указанных изображений
predict:
	@echo "Предсказание параметров..."
	$(VENV)\Scripts\activate && python predict_parameters.py before_images/B.tiff after_images/B.tiff