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

gifFilename = '../gif/processing_animation.gif';

% Определение параметров для различных шагов обработки
sensitivities = [0.7, 0.8, 0.9]; % Параметры чувствительности для пороговой обработки
radii = [3, 6, 9]; % Параметры радиуса для эрозии
iterationsList = [50, 100, 150]; % Количество итераций для активных контуров

% Создание фигуры
h = figure('visible', 'off'); % Скрытие фигуры, чтобы она не отображалась

% Начальные параметры
delayTime = 1.5; % Время задержки для каждого кадра
pauseTime = 5; % Время задержки между наборами параметров

% Создание GIF-анимации для каждого набора параметров
isAppend = false; % Первая запись в GIF (не append)

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

            % Этап: Отображение кластерного изображения
            captureFrame(h, RGBAfter, clusterImage, gifFilename, sensitivity, radius, iterations, numClusters, delayTime, isAppend);
            isAppend = true; % Далее использовать append

            % Пауза перед переходом к следующему набору параметров
            pauseFrames = pauseTime / delayTime;
        end
    end
end

% Закрытие фигуры
close(h);

disp('GIF создан успешно.');

function captureFrame(h, originalImage, clusterImage, gifFilename, sensitivity, radius, iterations, numClusters, delayTime, isAppend)
    figure(h);

    % Создание подзаголовков
    subplot(1, 2, 1);
    imshow(originalImage, 'InitialMagnification', 'fit');
    title('Original Image', 'FontSize', 14);

    subplot(1, 2, 2);
    imshow(clusterImage, 'InitialMagnification', 'fit');
    title(sprintf('Clustered Image\nClusters: %d', numClusters), 'FontSize', 14);

    % Добавление текста с параметрами
    paramText = annotation('textbox', [0.5, 1, 0, 0], 'string', ...
        sprintf('Sensitivity: %.2f, Radius: %d, Iterations: %d', sensitivity, radius, iterations), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'FitBoxToText', 'on', 'EdgeColor', 'none');

    frame = getframe(h);
    img = frame2im(frame); % Получение изображения из структуры кадра
    [imind, cm] = rgb2ind(img, 256, 'nodither');

    if isAppend
        imwrite(imind, cm, gifFilename, 'gif', 'WriteMode', 'append', 'DelayTime', delayTime);
    else
        imwrite(imind, cm, gifFilename, 'gif', 'Loopcount', inf, 'DelayTime', delayTime);
    end
    % Удаление аннотации после записи кадра в GIF
    delete(paramText);
end
