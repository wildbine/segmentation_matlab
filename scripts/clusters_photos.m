RGBAfter = imread('../54um_50x.tif');
RGBBefore = imread('../before_50x.tif');

RGBBefore = imresize(RGBBefore, [size(RGBAfter, 1), size(RGBAfter, 2)]);

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

% Определение параметров для различных шагов обработки
sensitivities = [0.7, 0.8, 0.9]; % Параметры чувствительности для пороговой обработки
radii = [3, 6, 9]; % Параметры радиуса для эрозии
iterationsList = [50, 100, 150]; % Количество итераций для активных контуров

% Создание папки для сохранения изображений
outputFolder = 'ClusterResults';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

index = 1; % Индекс для имен файлов

for sensitivity = sensitivities
    for radius = radii
        for iterations = iterationsList
            % Пороговая обработка разностного изображения
            diffBW = imbinarize(diffImage, 'adaptive', 'Sensitivity', sensitivity, 'ForegroundPolarity', 'bright');

            % Пороговая обработка и инверсия маски
            X = rgb2lab(RGBAfter);
            BW = imbinarize(rgb2gray(RGBAfter), 'adaptive', 'Sensitivity', 0.63, 'ForegroundPolarity', 'bright');
            BW = imcomplement(BW);
            BW = BW & diffBW;

            % Заполнение дыр, очистка границ и эрозия маски
            BW = imfill(BW, 'holes');
            BW = imclearborder(BW, 4);
            se = strel('octagon', radius); % Использование октагонального элемента
            BW = imerode(BW, se);

            % Дополнительные шаги расширения и эрозии
            se = strel('disk', radius);
            BW = imdilate(BW, se);
            BW = imerode(BW, se);

            % Удаление мелких компонентов и расширение
            BW = imfill(BW, 'holes');
            BW = bwareaopen(BW, 500);
            se = strel('disk', 5);
            BW = imdilate(BW, se);
            BW = imfill(BW, 'holes');

            % Применение активных контуров (Chan-Vese)
            BW = activecontour(X, BW, iterations, 'Chan-Vese');
            BW = imfill(BW, 'holes');
            BW = bwareaopen(BW, 500);

            % Кластеризация
            [labeledImage, numClusters] = bwlabel(BW);

            % Преобразование кластеров в RGB изображение
            clusterImage = label2rgb(labeledImage);

            % Добавление текстовых аннотаций на изображение
            position = [10 10; 10 100; 10 200; 10 300]; % Позиции для текста
            box_color = {'black'}; % Цвет рамки
            annotatedImage = insertText(clusterImage, position, ...
                {sprintf('Sensitivity: %.2f', sensitivity), ...
                 sprintf('Radius: %d', radius), ...
                 sprintf('Iterations: %d', iterations), ...
                 sprintf('Clusters: %d', numClusters)}, ...
                 'FontSize', 42, 'BoxColor', box_color, 'BoxOpacity', 0.7, 'TextColor', 'white');

            % Сохранение изображения
            imageName = sprintf('ClusterResult_S%.2f_R%d_I%d.png', sensitivity, radius, iterations);
            imwrite(annotatedImage, fullfile(outputFolder, imageName));

            index = index + 1;
        end
    end
end

disp('Ключевые результаты сохранены в папке ClusterResults с аннотациями параметров.');



