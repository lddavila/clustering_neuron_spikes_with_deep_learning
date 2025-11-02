function [valley_1_cv,valley_2_cv] = calculate_cv_of_valleys(spikes)
% the goal of this is to find some kind of measurement of the corruption of
% the spikes in the valleys by taking the cv of the valley
%a very small cv indicates low corruption at the valley
% a large cv indicates high corruption possibly signalling a lower quality
% cluster probably with less accuracy 

%we'll get the cv along all the channels for robustness
%first dim of spikes indicates the change of the spikes
valley_1_cv = nan(size(spikes,1),1);
valley_2_cv = nan(size(spikes,1),1);
for i=1:size(spikes,1)
    %find the max of every spike
    %the first valley is located at the min of every spike before the peak
    flattened_spikes = squeeze(spikes(i,:,:));
    [~,idx] = max(flattened_spikes,[],2);

    first_half_of_all_spikes = flattened_spikes(:,1:idx);
    second_half_of_all_spikes = flattened_spikes(:,idx+1:idx+50);

    %now find the cv of the first valleys
    valley_1 = min(first_half_of_all_spikes,[],2);
    valley_1_cv(i) = std(valley_1) / mean(abs(valley_1));

    %now do the same for the cv of the second set of vallyes
    valley_2 = min(second_half_of_all_spikes,[],2);
    valley_2_cv(i) = std(valley_2) / mean(abs(valley_2));


end
end