function [BW, maskedImage, labeledImage, numClusters] = segmentImage(RGB)
    % Convert RGB image into L*a*b* color space.
    X = rgb2lab(RGB);

    % Threshold image with adaptive threshold
    BW = imbinarize(im2gray(RGB), 'adaptive', 'Sensitivity', 0.63, 'ForegroundPolarity', 'bright');

    % Invert mask
    BW = imcomplement(BW);

    % Fill holes
    BW = imfill(BW, 'holes');

    % Clear borders and keep the objects touching the borders
    BW = imclearborder(BW, 4);

    % Erode mask with octagon
    radius = 6;
    se = strel('octagon', radius);
    BW = imerode(BW, se);

    % Fill holes
    BW = imfill(BW, 'holes');

    % Remove small connected components
    BW = bwareaopen(BW, 500);

    % Dilate to merge close objects
    se = strel('disk', 5);
    BW = imdilate(BW, se);

    % Fill holes again
    BW = imfill(BW, 'holes');

    % Active contour
    iterations = 100;
    BW = activecontour(X, BW, iterations, 'Chan-Vese');

    % Fill holes again for larger regions
    BW = imfill(BW, 'holes');

    % Remove small connected components again
    BW = bwareaopen(BW, 500);

    % Create masked image
    maskedImage = RGB;
    maskedImage(repmat(~BW, [1 1 3])) = 0;

    % Label connected components
    [labeledImage, numClusters] = bwlabel(BW);

    % Merge close clusters
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

    % Update number of clusters
    numClusters = max(labeledImage(:));

    % Display the number of clusters
    fprintf('Number of clusters: %d\n', numClusters);

% Создаем массив для хранения меток кластеров
clusterLabels = cell(1, numClusters);

% Проходим по всем меткам кластеров и сохраняем их в массив
for i = 1:numClusters
    clusterLabels{i} = labeledImage == i;
save('cluster_labels.mat', 'clusterLabels');
end
