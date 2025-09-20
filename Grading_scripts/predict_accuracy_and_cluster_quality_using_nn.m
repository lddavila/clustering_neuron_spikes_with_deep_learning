function [accuracy_pred,quality_pred,mua_or_not_pred] = predict_accuracy_and_cluster_quality_using_nn(first_dimension,second_dimension,peaks,config,peaks_in_cluster)
quality_pred = NaN;
   
colors = distinguishable_colors(1); %will always use the same colors
my_gray = [0.5 0.5 0.5];
%hold on
f = figure('Visible','off');


%to ensure that the peaks have the same dimension we ensure that the numer of rows is greater than number of cols
%this should always be true because it's impossible to have more wires than spikes
%if it isn't the case then we transpose it so that it is
if size(peaks,1) < size(peaks,2)
    peaks = peaks.';
end
scatter(peaks(:, first_dimension), peaks(:, second_dimension), 2,my_gray);
%for the above scatter to work the number of cols in peaks must correspond to the number of wires in the current tetrode


if isempty(peaks_in_cluster)
    accuracy_pred = NaN;
    close(f);
    return
end

if config.ON_HPC
    accuracy_nn = importdata(config.FP_TO_ACC_PREDICTING_NN_ON_HPC);
    accuracy_nn = accuracy_nn.net;
    mua_or_not_nn = importdata(config.FP_TO_MUA_OR_NOT_PREDICTING_NN_ON_HPC);
    mua_or_not_nn = mua_or_not_nn.net;
else
    accuracy_nn = importdata(config.FP_TO_ACC_PREDICTING_NN);
    accuracy_nn = accuracy_nn.net;
    mua_or_not_nn = importdata(config.FP_TO_MUA_OR_NOT_PREDICTING_NN);
    mua_or_not_nn = mua_or_not_nn.net;
end
peaks_in_cluster(peaks_in_cluster > size(peaks,1)) = [];
cluster = peaks(peaks_in_cluster, :);
cluster_x = cluster(:, first_dimension); %column should correspond to the rep wire
cluster_y = cluster(:, second_dimension); %column should correspond to the second rep wire
hold on;
scatter(cluster_x, cluster_y, 2,colors(1,:))
axis equal;
axis off;


frame = getframe(f);
RGB   = frame2im(frame);   % now proceed to gray + imresize
close(f);
grayscaled_image =rgb2gray(RGB);
resized_and_gray_scaled_image = imresize(grayscaled_image,[224,224]);
pred_accuracy_class = predict(accuracy_nn,single(resized_and_gray_scaled_image));
[~,accuracy_pred] = max(pred_accuracy_class);
accuracy_pred = accuracy_pred-1;

% pred_quality_class = predict(quality_nn,single(resized_and_gray_scaled_image));
% [~,quality_pred] = max(pred_quality_class);
% quality_pred = quality_pred-1;

mua_or_not_class = predict(mua_or_not_nn,single(resized_and_gray_scaled_image));
[~,mua_or_not_pred] = max(mua_or_not_class);
mua_or_not_pred = mua_or_not_pred-1;
%delete(file_save_name);
%imshow(resized_and_gray_scaled_image)
%imwrite(resized_and_gray_scaled_image,file_save_name);

end