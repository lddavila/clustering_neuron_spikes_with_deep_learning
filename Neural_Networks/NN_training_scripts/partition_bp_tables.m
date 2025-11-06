function [cell_array_of_parititioned_bp_tables] = partition_bp_tables(blind_pass_table,split_by_recording)
%the goal of this function to to separate blind pass tables
%take 30% of the appreances in the bp table and separate them
%the remaining 70% will be left in the blind pass table

groupcounts_by_recording = groupcounts(blind_pass_table,"recording_name");
if split_by_recording
    cell_array_of_parititioned_bp_tables = cell(size(groupcounts_by_recording,1),2);
else
    cell_array_of_parititioned_bp_tables = cell(1,2);
end
if split_by_recording
    for i=1:size(groupcounts_by_recording,1)
        %get all examples of the current recording
        current_recording_examples = blind_pass_table(blind_pass_table{:,"recording_name"}==groupcounts_by_recording{i,"recording_name"},:);

        %now get the unit group counts per recording
        groupcounts_for_units = groupcounts(current_recording_examples,"Max_Overlap_Unit");

        %now randomly choose 30% of units
        units_to_take = groupcounts_for_units{randperm(size(groupcounts_for_units,1),round(size(groupcounts_for_units,1) * .30)),"Max_Overlap_Unit"}.';

        units_to_leave = setdiff(groupcounts_for_units{:,"Max_Overlap_Unit"},units_to_take).';

        cell_array_of_parititioned_bp_tables{i,1} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_leave,2),:);
        cell_array_of_parititioned_bp_tables{i,2} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_take,2),:);
    end
else
    %get all examples of the current recording
    current_recording_examples = blind_pass_table;

    %now get the unit group counts per recording
    groupcounts_for_units = groupcounts(current_recording_examples,"Max_Overlap_Unit");

    %now randomly choose 30% of units
    units_to_take = groupcounts_for_units{randperm(size(groupcounts_for_units,1),round(size(groupcounts_for_units,1) * .30)),"Max_Overlap_Unit"}.';

    units_to_leave = setdiff(groupcounts_for_units{:,"Max_Overlap_Unit"},units_to_take).';

    cell_array_of_parititioned_bp_tables{1,1} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_leave,2),:);
    cell_array_of_parititioned_bp_tables{1,2} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_take,2),:);
end

end