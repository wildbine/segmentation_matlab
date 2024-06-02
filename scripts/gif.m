% Чтение изображений до и после деформации
RGBAfter = imread('../54um_50x.tif');
RGBBefore = imread('../before_50x.tif');

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

% Имя файла для GIF
gifFilename = '../gif/smooth_difference_images.gif';

% Начальные параметры
sensitivityValues = 0.5:0.02:0.95; % Шаг уменьшен для большей плавности
radiusValues = 1:1:10; % Различные радиусы для структурного элемента

% Создание фигуры
h = figure('visible', 'off'); % Скрытие фигуры, чтобы она не отображалась

for sensitivity = sensitivityValues
    for radius = radiusValues
        % Применение пороговой функции с изменяемой чувствительностью
        diffBW = imbinarize(diffImage, 'adaptive', 'Sensitivity', sensitivity, 'ForegroundPolarity', 'bright');
        
        % Эрозия маски с помощью структурного элемента
        se = strel('disk', radius);
        diffBW = imerode(diffBW, se);

        % Создание фигуры
        set(gcf, 'Position', [100, 100, 800, 600]); % Установка размеров окна фигуры

        % Отображение порогового разностного изображения
        imshow(diffBW, 'InitialMagnification', 'fit');
        title(sprintf('Thresholded Difference Image\nSensitivity: %.2f, Radius: %d', sensitivity, radius), 'FontSize', 14);
        set(gca, 'FontSize', 12);

        % Захват текущего кадра
        frame = getframe(h);
        img = frame2im(frame);
        [imind, cm] = rgb2ind(img, 256);

        % Запись кадра в GIF
        if sensitivity == sensitivityValues(1) && radius == radiusValues(1)
            imwrite(imind, cm, gifFilename, 'gif', 'Loopcount', inf, 'DelayTime', 0.2);
        else
            imwrite(imind, cm, gifFilename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.2);
        end
    end
end

% Закрытие фигуры
close(h);

disp('GIF создан успешно.');