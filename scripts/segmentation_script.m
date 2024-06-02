% Путь к изображениям до и после деформации
imagePathAfter = '../54um_50x.tif';
imagePathBefore = '../before_50x.tif';
% Чтение изображений
RGBAfter = imread(imagePathAfter);
RGBBefore_2 = imread(imagePathBefore);
RGBBefore = imresize(RGBBefore_2, [size(RGBAfter, 1), size(RGBAfter, 2)]);
% Вызов функции сегментации с двумя изображениями
[BW, maskedImage, labeledImage, numClusters] = segmentImage(RGBAfter, RGBBefore);

% Визуализация результатов
figure;

subplot(3, 2, 1);
imshow(RGBAfter);
title('Original Image After Deformation');

subplot(3, 2, 2);
imshow(BW);
title('Binary Mask');

subplot(3, 2, 3);
imshow(RGBBefore_2);
title('Original Image');

subplot(3, 2, 4);
imshow(maskedImage);
title('Masked Image');

subplot(3, 2, 5);
imshow(label2rgb(labeledImage, 'jet', 'k', 'shuffle'));
title(sprintf('Segmented Image - Clusters: %d', numClusters));