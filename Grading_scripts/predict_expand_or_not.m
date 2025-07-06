function [expand_or_not_class] = predict_expand_or_not(first_dimension,second_dimension,peaks,config,peaks_in_cluster)
colors = distinguishable_colors(1); %will always use the same colors
my_gray = [0.5 0.5 0.5];
hold on
f = figure;




if isempty(peaks_in_cluster)
    expand_or_not_class = NaN;
    return
end

if config.ON_HPC
    expand_or_not_nn = importdata(config.FP_TO_EXPAND_OR_DONT_NN_ON_HPC);
    expand_or_not_nn = expand_or_not_nn.net;
else
    expand_or_not_nn = importdata(config.FP_TO_EXPAND_OR_DONT_NN);
    expand_or_not_nn = expand_or_not_nn.net;
end

%to ensure that the peaks have the same dimension we ensure that the numer of rows is greater than number of cols
%this should always be true because it's impossible to have more wires than spikes
%if it isn't the case then we transpose it so that it is
if size(peaks,1) < size(peaks,2)
    peaks = peaks.';
end

peaks_in_cluster(peaks_in_cluster > size(peaks,1)) = [];
cluster = peaks(peaks_in_cluster, :);
cluster_x = cluster(:, first_dimension); %column should correspond to the rep wire
cluster_y = cluster(:, second_dimension); %column should correspond to the second rep wire


n = config.NUM_STDS_AROUND_CLUSTER; %number of standard deviations, theres no one right standard deviation, but this one seems to be good for my purposes

cluster_x_mean = mean(cluster_x,'all');
cluster_x_std = std(cluster_x);
n_stds_right_of_cluster = cluster_x_mean+ (n*cluster_x_std);
n_std_left_of_cluster = cluster_x_mean - (n*cluster_x_std);

cluster_y_mean = mean(cluster_y,"all");
cluster_y_std = std(cluster_y);
n_stds_above_cluster = cluster_y_mean+ (n*cluster_y_std);
n_std_below_cluster = cluster_y_mean - (n*cluster_y_std);


c1 = peaks(:,first_dimension) < n_stds_right_of_cluster & peaks(:,first_dimension) > n_std_left_of_cluster;
c2 = peaks(:,second_dimension) < n_stds_above_cluster & peaks(:,second_dimension) > n_std_below_cluster;


data = peaks(c1 & c2,:);


scatter(data(:, first_dimension), data(:, second_dimension), 2,my_gray);
%for the above scatter to work the number of cols in peaks must correspond to the number of wires in the current tetrode

hold on;
scatter(cluster_x, cluster_y, 2,colors(1,:))
axis equal;
axis off;

randomized_temp_file_number_sequence = randi(1e9, 1, 10);

file_save_name = strjoin(string(randomized_temp_file_number_sequence))+".png"; %this file will be deleted
% so we just randomly generate 10 numbers between 1 and billion and use this as a file name to avoid a multi threaded process accidentally
%reading the same file
saveas(f,file_save_name);
close(f);
RGB = imread(file_save_name);
grayscaled_image =rgb2gray(RGB);
resized_and_gray_scaled_image = imresize(grayscaled_image,[224,224]);


expand_or_not_class = predict(expand_or_not_nn,single(resized_and_gray_scaled_image));
[~,expand_or_not] = max(expand_or_not_class);
expand_or_not_class = expand_or_not-1;
delete(file_save_name);
%imshow(resized_and_gray_scaled_image)
% imwrite(resized_and_gray_scaled_image,file_save_name);

end