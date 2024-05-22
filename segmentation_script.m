% Основной скрипт для запуска сегментации и визуализации результата

% Путь к изображению
imagePath = '54um_50x.tif';

% Чтение изображения
RGB = imread(imagePath);

% Вызов функции сегментации
[BW, maskedImage, labeledImage, numClusters] = segmentImage(RGB);

% Визуализация результатов
figure;

subplot(2, 2, 1);
imshow(RGB);
title('Original Image');

subplot(2, 2, 2);
imshow(BW);
title('Binary Mask');

subplot(2, 2, 3);
imshow(maskedImage);
title('Masked Image');

subplot(2, 2, 4);
imshow(label2rgb(labeledImage, 'jet', 'k', 'shuffle'));
title(sprintf('Segmented Image - Clusters: %d', numClusters));