load('cluster_labels.mat');
% Перебираем каждый кластер и отображаем его как изображение
for i = 1:numel(clusterLabels)
    figure;
    imshow(clusterLabels{i});
    title(sprintf('Cluster %d', i));
end