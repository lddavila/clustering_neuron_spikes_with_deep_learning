function [test_data_set] = establish_test_set_to_test_merge_or_dont_pipeline(blind_pass_table,options)
arguments
    blind_pass_table table
    options.do_something = false;
end
rng(0)
blind_pass_table(isnan(blind_pass_table.num_of_channels),:) = [];
blind_pass_table(isnan(blind_pass_table.Max_Overlap_Unit),:) = [];
blind_pass_table(blind_pass_table.num_of_channels==1,:) = [];

%get the unique numbers of channels
unique_num_channels = unique(blind_pass_table.num_of_channels);



% now get the units which only appear on combinations of 1,2,3,...,n
pairs_of_2_lists = {};
cell_array_of_combo_map = {};
for j=1:size(unique_num_channels)
    all_combos = nchoosek(1:length(unique_num_channels),j);
    for i=1:size(all_combos,1)
        targeted_num_channels = unique_num_channels(all_combos(i,:));
        only_target = unique(blind_pass_table{ismember(blind_pass_table{:,"num_of_channels"},targeted_num_channels),"Max_Overlap_Unit"});
        pairs_of_2_lists{end+1} = only_target;
        cell_array_of_combo_map{end+1} = targeted_num_channels.';
    end
end

data_map = [cell_array_of_combo_map.',pairs_of_2_lists.'];

%now get samples of each row in the dataset 
test_data_set = [];
units_already_used = [];
num_of_units_per_subset = 10;
how_many_rows_per_subset = 50;
for i=1:size(data_map)
    current_num_channels = data_map{i,1};
    curr_units = data_map{i,2};
    rand_units = curr_units(randi(length(curr_units),num_of_units_per_subset,1));
    rand_units = setdiff(rand_units,units_already_used);
    only_curr_num_ch = blind_pass_table(ismember(blind_pass_table.num_of_channels,current_num_channels) & ismember(blind_pass_table.Max_Overlap_Unit,curr_units),:);
    units_already_used = [units_already_used;rand_units];
    random_rows = only_curr_num_ch(randi(height(only_curr_num_ch),how_many_rows_per_subset,1),:);
    test_data_set = [test_data_set;random_rows];
end
end