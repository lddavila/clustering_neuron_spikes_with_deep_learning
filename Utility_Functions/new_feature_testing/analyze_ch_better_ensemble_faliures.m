function [] = analyze_ch_better_ensemble_faliures(idx_of_lowest,unscaled_certainties,blind_pass_table,distance_from_min_uncertainty,options)
arguments
    idx_of_lowest double
    unscaled_certainties double
    blind_pass_table table
    distance_from_min_uncertainty double
    options.bin_size double = 10;
    options.normalize_by_probability double = 0;
end

%first we should try to categorize the performance faliures
bins = 1:options.bin_size:100;
figure;
if options.normalize_by_probability
    histogram(distance_from_min_uncertainty,'BinEdges',bins,'Normalization','probability');
else
    histogram(distance_from_min_uncertainty,'BinEdges',bins);
end
xlabel("Distance from True Accuracy")
ylabel("Frequency")
title("Categories of faliure cases")

%now lets analyze each of these faliure cases by seeing the distribution of each bin plotting the 
figure;
for i=1:length(bins)-1
    in_current_bin = distance_from_min_uncertainty >= bins(i) & distance_from_min_uncertainty <bins(i+1);
    tiledlayout("flow")
    nexttile();
    histogram(blind_pass_table.accuracy(in_current_bin),'BinEdges',1:1:100);
    xlabel("Accuracy")
    ylabel("Frequency");
    title(sprintf("Distance from true accuracy ranging from %.2f to %.2f",bins(i),bins(i+1)));
end


end