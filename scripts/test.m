% Чтение изображений до и после деформации
RGBAfter = imread('../54um_50x.tif');
RGBBefore = imread('../before_50x.tif');
radius = 6;
maxNumberOfPixObj = 500;
% Изменение размера изображения до деформации до размеров изображения после деформации
RGBBefore = imresize(RGBBefore, [size(RGBAfter, 1), size(RGBAfter, 2)]);

% Преобразование изображений в оттенки серого
grayAfter = rgb2gray(RGBAfter);
grayBefore = rgb2gray(RGBBefore);

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

grayAfter = double(grayAfter) / max(double(grayAfter(:)));
diffBW = grayAfter > diffImage;

X = rgb2lab(RGBAfter);
BW = imbinarize(grayAfter, 'adaptive', 'Sensitivity', 0.63, 'ForegroundPolarity', 'bright');
BW = imcomplement(BW);
BW = BW & diffBW;

figure;
imshow(BW);
title('Initial Binary Mask');

% Обработка маски
BW = imfill(BW, 'holes');
BW = imclearborder(BW, 4);
se = strel('octagon', radius);
BW = imerode(BW, se);

BW = imfill(BW, 'holes');
BW = bwareaopen(BW, maxNumberOfPixObj);
se = strel('disk', (radius>2)*radius + (radius-1<=1)*2);
BW = imdilate(BW, se);
BW = imfill(BW, 'holes');

figure;
imshow(BW);
title('Eroded Binary Mask');

% Активные контуры
iterations = 50;
BW = activecontour(X, BW, iterations, 'Chan-Vese');
BW = imfill(BW, 'holes');
BW = bwareaopen(BW, maxNumberOfPixObj);

figure;
imshow(BW);
title('Binary Mask After Active Contour');

% Маркировка связанных компонентов
[labeledImage, numClusters] = bwlabel(BW);

% Объединение близких кластеров
minClusterDist = 5;
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
