function [cell_array_of_parititioned_bp_tables] = partition_bp_tables(blind_pass_table,split_by_recording,options)
arguments
    blind_pass_table table;
    split_by_recording logical;
    options.split_at double = .3;
    options.split_into_folds logical = false;
    options.each_fold_fraction = .1;
    options.split_into_test_train_val = false;
    options.train_test_val_split = [0.5 .25 .25];
end
%the goal of this function to to separate blind pass tables
%take 30% of the appreances in the bp table and separate them
%the remaining 70% will be left in the blind pass table
if split_by_recording
    groupcounts_by_recording = groupcounts(blind_pass_table,"recording_name");
    cell_array_of_parititioned_bp_tables = cell(size(groupcounts_by_recording,1),2);
else
    cell_array_of_parititioned_bp_tables = cell(1,2);
end

if ~options.split_into_folds
    if split_by_recording
        for i=1:size(groupcounts_by_recording,1)
            %get all examples of the current recording
            current_recording_examples = blind_pass_table(blind_pass_table{:,"recording_name"}==groupcounts_by_recording{i,"recording_name"},:);

            %now get the unit group counts per recording
            groupcounts_for_units = groupcounts(current_recording_examples,"Max_Overlap_Unit");

            %now randomly choose 30% of units
            units_to_take = groupcounts_for_units{randperm(size(groupcounts_for_units,1),round(size(groupcounts_for_units,1) * options.split_at)),"Max_Overlap_Unit"}.';

            units_to_leave = setdiff(groupcounts_for_units{:,"Max_Overlap_Unit"},units_to_take).';

            cell_array_of_parititioned_bp_tables{i,1} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_leave,2),:);
            cell_array_of_parititioned_bp_tables{i,2} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_take,2),:);
        end
    else
        
        %get all examples of the current recording
        current_recording_examples = blind_pass_table;

        %now get the unit group counts per recording
        groupcounts_for_units = groupcounts(current_recording_examples,"Max_Overlap_Unit");
        if ~options.split_into_test_train_val
            %now randomly choose 30% of units
            units_to_take = groupcounts_for_units{randperm(size(groupcounts_for_units,1),round(size(groupcounts_for_units,1) * options.split_at)),"Max_Overlap_Unit"}.';
            units_to_leave = setdiff(groupcounts_for_units{:,"Max_Overlap_Unit"},units_to_take).';
            cell_array_of_parititioned_bp_tables{1,1} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_leave,2),:);
            cell_array_of_parititioned_bp_tables{1,2} = current_recording_examples(any(current_recording_examples{:,"Max_Overlap_Unit"}==units_to_take,2),:);
        else
            if sum(options.train_test_val_split) ~= 1
                disp("Error invalid training test validation split")
                disp(options.train_test_val_split)
                disp("Values must sum to equal 1")
            end
            cell_array_of_parititioned_bp_tables = cell(1,3);
            training_data_idxs = randperm(height(groupcounts_for_units),round(height(groupcounts_for_units) * options.train_test_val_split(1)));
            training_units = groupcounts_for_units{training_data_idxs,"Max_Overlap_Unit"};
            units_remaining = setdiff(groupcounts_for_units{:,"Max_Overlap_Unit"},training_units);
            number_of_units_that_should_be_in_validation = round(height(groupcounts_for_units) * options.train_test_val_split(2));
            number_of_units_that_should_be_in_test = round(height(groupcounts_for_units) * options.train_test_val_split(3));

            validation_idxs = randperm(length(units_remaining),number_of_units_that_should_be_in_validation);
            validation_units = units_remaining(validation_idxs);
            units_remaining = setdiff(units_remaining,validation_units);

            testing_units = units_remaining;

            cell_array_of_parititioned_bp_tables{1} = current_recording_examples(ismember(current_recording_examples{:,"Max_Overlap_Unit"},training_units),:);
            cell_array_of_parititioned_bp_tables{2} = current_recording_examples(ismember(current_recording_examples{:,"Max_Overlap_Unit"},validation_units),:);
            cell_array_of_parititioned_bp_tables{3} = current_recording_examples(ismember(current_recording_examples{:,"Max_Overlap_Unit"},testing_units),:);
        end
    end
else
    groupcounts_for_units = groupcounts( ...
        blind_pass_table, "Max_Overlap_Unit");

    all_possible_units = groupcounts_for_units.Max_Overlap_Unit;
    num_units = numel(all_possible_units);

    % Shuffle once, then divide the shuffled units into folds
    all_possible_units = all_possible_units(randperm(num_units));

    num_folds = round(1 / options.each_fold_fraction);

    cell_array_of_parititioned_bp_tables = cell(num_folds, 1);

    % Divide unit indices as evenly as possible
    fold_edges = round(linspace(0, num_units, num_folds + 1));

    for i = 1:num_folds
        fold_indices = (fold_edges(i) + 1):fold_edges(i + 1);
        fold_units = all_possible_units(fold_indices);

        rows_in_fold = ismember( ...
            blind_pass_table.Max_Overlap_Unit, ...
            fold_units);

        cell_array_of_parititioned_bp_tables{i} = ...
            blind_pass_table(rows_in_fold, :);
    end

end
end