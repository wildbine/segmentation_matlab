% Чтение изображений до и после деформации
RGBAfter = imread('54um_50x.tif');
RGBBefore = imread('before_50x.tif');

% Изменение размера изображения до деформации до размеров изображения после деформации
RGBBefore = imresize(RGBBefore, [size(RGBAfter, 1), size(RGBAfter, 2)]);

% Преобразование изображений в оттенки серого
grayAfter = rgb2gray(RGBAfter);
grayBefore = rgb2gray(RGBBefore);

% Создание фигуры с увеличенными изображениями
figure;
set(gcf, 'Position', [400, 50, 600, 300]); % Установка размеров окна фигуры

% Отображение изображения до деформации
subplot(1, 2, 1);
imshow(grayBefore, 'InitialMagnification', 'fit'); % Увеличение изображения по размеру подграфика
title('Grayscale Image Before Deformation', 'FontSize', 14); % Увеличение шрифта заголовка
set(gca, 'FontSize', 8); % Увеличение шрифта осей

% Отображение изображения после деформации
subplot(1, 2, 2);
imshow(grayAfter, 'InitialMagnification', 'fit'); % Увеличение изображения по размеру подграфика
title('Grayscale Image After Deformation', 'FontSize', 14); % Увеличение шрифта заголовка
set(gca, 'FontSize', 8); % Увеличение шрифта осей

diffImage = imabsdiff(grayAfter, grayBefore);

figure;
imshow(diffImage);
title('Difference Image');

diffBW = imbinarize(diffImage, 'adaptive', 'Sensitivity', 0.9, 'ForegroundPolarity', 'bright');

figure;
imshow(diffBW);
title('Binary Difference Image');

X = rgb2lab(RGBAfter);
BW = imbinarize(rgb2gray(RGBAfter), 'adaptive', 'Sensitivity', 0.63, 'ForegroundPolarity', 'bright');
BW = imcomplement(BW);
BW = BW & diffBW;

figure;
imshow(BW);
title('Initial Binary Mask');


BW = imfill(BW, 'holes');
BW = imclearborder(BW, 4);
radius = 6;
se = strel('octagon', radius);
BW = imerode(BW, se);

figure;
imshow(BW);
title('Eroded Binary Mask');

BW = imfill(BW, 'holes');
BW = bwareaopen(BW, 500);
se = strel('disk', 5);
BW = imdilate(BW, se);
BW = imfill(BW, 'holes');

iterations = 50;
BW = activecontour(X, BW, iterations, 'Chan-Vese');
BW = imfill(BW, 'holes');
BW = bwareaopen(BW, 500);

figure;
imshow(BW);
title('Binary Mask After Active Contour');