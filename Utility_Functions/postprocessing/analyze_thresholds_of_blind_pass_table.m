function [] = analyze_thresholds_of_blind_pass_table(blind_pass_table)
unique_thresholds = unique(blind_pass_table.("Z Score"));

for i=1:length(unique_thresholds)
    figure;
    c1 = blind_pass_table{:,"Z Score"} == unique_thresholds(i);
    histogram(blind_pass_table{c1,"accuracy"},'BinEdges',0:5:100)
    xlabel("Accuracy");
    ylabel("Frequency");
    title("Multiplier: "+string(unique_thresholds(i)));

end

end