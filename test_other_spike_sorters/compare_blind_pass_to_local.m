function [comparison_table] = compare_blind_pass_to_local(blind_pass_table,other_table_agreement_matrix)
num_gt_units = size(other_table_agreement_matrix,2)-1;
max_accuracy_for_gt_unit_our_ss = nan(num_gt_units,1);
max_accuracy_for_other_ss = nan(num_gt_units,1);
for i=1:num_gt_units
    %disp(i);
    max_accuracy_for_other_ss(i) = max(other_table_agreement_matrix(:,i+1));
    max_accuracy_from_bp = max(blind_pass_table{blind_pass_table{:,"Max_Overlap_Unit"}==i,"accuracy"});
    if ~isempty(max_accuracy_from_bp)
        max_accuracy_for_gt_unit_our_ss(i) = max_accuracy_from_bp;
    else
        max_accuracy_for_gt_unit_our_ss(i) = 0;
    end
end
gt_units = (1:num_gt_units).';
comparison_table = table(gt_units,max_accuracy_for_gt_unit_our_ss,max_accuracy_for_other_ss);
display(comparison_table);
disp("Number of times our algo beat the other ss")
disp(sum(comparison_table{:,"max_accuracy_for_gt_unit_our_ss"}>comparison_table{:,"max_accuracy_for_other_ss"}));
end