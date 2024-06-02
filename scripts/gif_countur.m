% Чтение изображений до и после деформации
RGBAfter = imread('../54um_50x.tif');
RGBBefore = imread('../before_50x.tif');

% Изменение размера изображения до деформации до размеров изображения после деформации
RGBBefore = imresize(RGBBefore, [size(RGBAfter, 1), size(RGBAfter, 2)]);

% Преобразование изображений в оттенки серого
grayAfter = rgb2gray(RGBAfter);
grayBefore = rgb2gray(RGBBefore);

% Вычисление разностного изображения
diffImage = imabsdiff(grayAfter, grayBefore);

% Имя файла для GIF
gifFilename = '../gif/processing_animation.gif';

% Определение параметров для различных шагов обработки
sensitivities = [0.6, 0.7, 0.8, 0.9]; % Параметры чувствительности для пороговой обработки
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

            % Этап 1: Отображение порогового разностного изображения
            captureFrame(h, diffBW, gifFilename, sensitivity, radius, iterations, delayTime, isAppend, 'DifferenceImage');
            isAppend = true; % Далее использовать append

            % Заполнение дыр, очистка границ и эрозия маски
            BW = imfill(BW, 'holes');
            BW = imclearborder(BW, 4);
            se = strel('octagon', radius); % Использование октагонального элемента
            BW = imerode(BW, se);

            % Дополнительные шаги расширения и эрозии
            se = strel('disk', radius);
            BW = imdilate(BW, se);
            BW = imerode(BW, se);

            % Этап 2: Отображение эродированного изображения
            captureFrame(h, BW, gifFilename, sensitivity, radius, iterations, delayTime, isAppend, 'ErodeMask');

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

            % Этап 3: Отображение итогового изображения
            captureFrame(h, BW, gifFilename, sensitivity, radius, iterations, delayTime, isAppend, 'Chan-Vese');

            maskedImage = RGBAfter;
            maskedImage(repmat(~BW, [1 1 3])) = 0;

            captureFrame(h, maskedImage, gifFilename, sensitivity, radius, iterations, delayTime, isAppend, 'MaskedImage');
            % Пауза перед переходом к следующему набору параметров
            pauseFrames = pauseTime / delayTime;
        end
    end
end

% Закрытие фигуры
close(h);

disp('GIF создан успешно.');

function captureFrame(h, BW, gifFilename, sensitivity, radius, iterations, delayTime, isAppend, name)
    figure(h);
    imshow(BW, 'InitialMagnification', 'fit');
    title(sprintf('%s\nSensitivity: %.2f, Radius: %d, Iterations: %d', name, sensitivity, radius, iterations), 'FontSize', 14);
    set(gca, 'FontSize', 12);
    frame = getframe(h);
    img = frame2im(frame); % Получение изображения из структуры кадра
    [imind, cm] = rgb2ind(img, 256, 'nodither');

    % Переменная imind определена здесь
    if isAppend
        imwrite(imind, cm, gifFilename, 'gif', 'WriteMode', 'append', 'DelayTime', delayTime);
    else
        imwrite(imind, cm, gifFilename, 'gif', 'Loopcount', inf, 'DelayTime', delayTime);
    end
end