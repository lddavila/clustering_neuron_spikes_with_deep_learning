function rato_of_left_side_to_right_side = compute_incompleteness_ver_2(peaks)
%COMPUTE_INCOMPLETENESS Computes the incompleteness grade of the cluster.
%   below_threshold = COMPUTE_INCOMPLETENESS(peaks, tvals) returns the
%   percent of the cluster theoretically below threshold (i.e., how
%   incomplete the cluster is because of the threshold).
%
%   'peaks' is a vector of the peaks for spikes in the representative wire
%   for this cluster.
%
%   'tval' is the threshold values for the representative wire in
%   microvolts.



[n, xout] = hist(peaks, 21);
% mean_of_data = mean(peaks,"all");
% mode_of_data = mode(peaks,"all");
% median_of_data = median(peaks,"all");
% skewness_of_data = skewness(peaks);
%
%figure;
%histogram(peaks,21)
% title("Median:"+string(median_of_data)+" Mode:"+string(mode_of_data)+ " Mean"+string(mean_of_data)+ " Skewness:"+skewness_of_data);
[~, max_n] = max(n);

number_of_bins_to_left_of_max_bin = length(1:(max_n-1));
number_of_bins_to_right_of_max_bin = length((max_n+1):21);



%we want to calculate how many bins are to the left of the peak, and how many are on the right
%the grade will be a ratio of #bins left of biggest bin / #bins right of biggest bin
%in a perfectly symmetrical enviornment it will be 1

rato_of_left_side_to_right_side = number_of_bins_to_left_of_max_bin / number_of_bins_to_right_of_max_bin;


end