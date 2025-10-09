function [comparison_table] = compare_blind_pass_to_local(blind_pass_table,other_spike_sorter_accuracy_dict)

number_of_comparisons = string(keys(other_spike_sorter_accuracy_dict));

figure;
tiledlayout(length(number_of_comparisons)+1,1)

for k=1:length(number_of_comparisons)
    nexttile();
    current_other_spike_sorter = number_of_comparisons(k);
    spike_sorter = split(current_other_spike_sorter," ");
    spike_sorter = spike_sorter{end};
    other_table_agreement_matrix = other_spike_sorter_accuracy_dict(current_other_spike_sorter);
    num_gt_units = size(other_table_agreement_matrix,2);
    max_accuracy_for_gt_unit_our_ss = nan(num_gt_units,1);
    max_accuracy_for_other_ss = nan(num_gt_units,1);

    for i=1:num_gt_units
        max_accuracy_for_other_ss(i) = max(other_table_agreement_matrix{:,i});
        max_accuracy_from_bp = max(blind_pass_table{blind_pass_table{:,"Max_Overlap_Unit"}==i,"accuracy"});
        if ~isempty(max_accuracy_from_bp)
            max_accuracy_for_gt_unit_our_ss(i) = max_accuracy_from_bp;
        else
            max_accuracy_for_gt_unit_our_ss(i) = 0;
        end
    end
    gt_units = (1:num_gt_units).';
    comparison_table = table(gt_units,max_accuracy_for_gt_unit_our_ss,max_accuracy_for_other_ss);
    %disp("Number of times our algo beat the other ss")
    num_times_our_algo_breat_the_other_ss = sum(comparison_table{:,"max_accuracy_for_gt_unit_our_ss"}>comparison_table{:,"max_accuracy_for_other_ss"});
    bar(comparison_table{:,"max_accuracy_for_other_ss"});
    title(spike_sorter +" We beat "+string(num_times_our_algo_breat_the_other_ss)+" times");
    ylim([0,100])
end


nexttile();
bar(comparison_table{:,"max_accuracy_for_gt_unit_our_ss"})
title("Our Spike sorter");
ylim([0,100])






end