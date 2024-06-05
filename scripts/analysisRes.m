% Путь к изображениям до и после деформации
imagePathAfter = '../54um_50x.tif';
imagePathBefore = '../before_50x.tif';
% Чтение изображений
RGBAfter = imread(imagePathAfter);
RGBBefore_2 = imread(imagePathBefore);
RGBBefore = imresize(RGBBefore_2, [size(RGBAfter, 1), size(RGBAfter, 2)]);

% Вызов функции сегментации
[BW, maskedImage, labeledImage, numClusters] = segmentImage(RGBAfter, RGBBefore);

clusterOverlay = cat(3, zeros(size(labeledImage)), zeros(size(labeledImage)), ones(size(labeledImage)));

% Создание полупрозрачной маски
alpha = 0.2; % Степень прозрачности

% Создание изображения с наложением кластеров
overlayImage = im2double(RGBAfter); % Преобразование к double для точных вычислений

% Наложение кластеров на оригинальное изображение с учетом прозрачности
for i = 1:numClusters
    % Создание маски для текущего кластера
    clusterMask = labeledImage == i;
    clusterOverlayDouble = double(clusterOverlay);
    % Наложение кластера с учетом прозрачности
    for j = 1:3
        overlayImage(:,:,j) = overlayImage(:,:,j) .* ~clusterMask + ...
                          alpha * clusterOverlayDouble(:,:,j) .* clusterMask + ...
                          (1 - alpha) * overlayImage(:,:,j) .* clusterMask;
    end
end

% Преобразование изображения обратно в uint8 для отображения и сохранения
overlayImage = im2uint8(overlayImage);

% Отображение исходного изображения и изображения с наложением кластеров
figure;
imshow(overlayImage);
title('Изображение с полупрозрачными кластерами');

% Сохранение изображения с наложением кластеров
imwrite(overlayImage, 'overlayImage.png');
