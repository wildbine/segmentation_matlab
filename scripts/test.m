% Чтение изображений до и после деформации
RGBAfter = imread('../54um_50x.tif');
RGBBefore = imread('../before_50x.tif');

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

% Вычисление текстурных характеристик до деформации
glcmBefore = graycomatrix(grayBefore, 'Offset', [0 1], 'Symmetric', true);
statsBefore = graycoprops(glcmBefore, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});

% Вычисление текстурных характеристик после деформации
glcmAfter = graycomatrix(grayAfter, 'Offset', [0 1], 'Symmetric', true);
statsAfter = graycoprops(glcmAfter, {'Contrast', 'Correlation', 'Energy', 'Homogeneity'});

% Вычисление разностного изображения для каждой текстурной характеристики
diffContrast = abs(statsAfter.Contrast - statsBefore.Contrast);
diffCorrelation = abs(statsAfter.Correlation - statsBefore.Correlation);
diffEnergy = abs(statsAfter.Energy - statsBefore.Energy);
diffHomogeneity = abs(statsAfter.Homogeneity - statsBefore.Homogeneity);

% Объединение разностных изображений
diffImage = diffContrast + diffCorrelation + diffEnergy + diffHomogeneity;
diffImage = mat2gray(diffImage); % Нормализация разностного изображения

figure;
disp(diffImage);
title('Difference Image Based on Texture Analysis');

grayAfter = double(grayAfter) / max(double(grayAfter(:)));
diffBW = grayAfter > diffImage;

X = rgb2lab(RGBAfter);
BW = imbinarize(rgb2gray(RGBAfter), 'adaptive', 'Sensitivity', 0.63, 'ForegroundPolarity', 'bright');
BW = imcomplement(BW);
BW = BW & diffBW;

figure;
imshow(BW);
title('Initial Binary Mask');

% Обработка маски
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

% Активные контуры
iterations = 50;
BW = activecontour(X, BW, iterations, 'Chan-Vese');
BW = imfill(BW, 'holes');
BW = bwareaopen(BW, 500);

figure;
imshow(BW);
title('Binary Mask After Active Contour');

% Создание маскированного изображения
maskedImage = RGBAfter;
maskedImage(repmat(~BW, [1 1 3])) = 0;

figure;
imshow(maskedImage);
title('Masked Image');

% Маркировка связанных компонентов
[labeledImage, numClusters] = bwlabel(BW);

% Объединение близких кластеров
minClusterDist = 10;
stats = regionprops(labeledImage, 'Centroid');
centroids = cat(1, stats.Centroid);
for i = 1:numClusters
    for j = i+1:numClusters
        if norm(centroids(i,:) - centroids(j,:)) < minClusterDist
            labeledImage(labeledImage == j) = i;
        end
    end
end
labeledImage = bwlabel(labeledImage > 0);

% Обновление количества кластеров
numClusters = max(labeledImage(:));

% Отображение количества кластеров
fprintf('Number of clusters: %d\n', numClusters);
imshow(label2rgb(labeledImage, 'jet', 'k', 'shuffle'));
title(sprintf('Segmented Image - Clusters: %d', numClusters));