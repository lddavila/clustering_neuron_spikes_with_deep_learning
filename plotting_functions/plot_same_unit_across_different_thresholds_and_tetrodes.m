function [] = plot_same_unit_across_different_thresholds_and_tetrodes(blind_pass_table,which_unit,minimum_accuracy,config,number_to_downsample,fp_to_thresholds_in_mv,number_of_dpts_to_plot)

save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"single conf"));
min_accuracy_cond = blind_pass_table{:,"accuracy"} > minimum_accuracy;
unit_cond = blind_pass_table{:,"Max_Overlap_Unit"}== which_unit;

filtered_data = blind_pass_table(min_accuracy_cond & unit_cond,:);
unique_tetrodes_and_mults = unique([filtered_data{:,"Tetrode"},filtered_data{:,"Z Score"}],"rows");

%select any rows in the blind pass table whose tetrode is a member of unique_tetrodes
rows_to_plot = blind_pass_table(ismember(blind_pass_table{:,"Tetrode"},unique_tetrodes_and_mults(:,1)),:);

%get every unit that appears on those tetrodes
unique_units = unique(rows_to_plot{:,"Max_Overlap_Unit"});

%create a map from unit names to colors
unit_colors = distinguishable_colors(length(unique_units));
colors_map = containers.Map('KeyType','double','ValueType','any');
for i=1:length(unit_colors)
    colors_map(unique_units(i)) = unit_colors(i,:);
end

% now create an individual plot for each tetrode and threshold
% unique_tetrodes_and_mults(11:end,:) = [];
% for i=1:size(unique_tetrodes_and_mults,1)
%    rows_to_plot = blind_pass_table(blind_pass_table{:,"Tetrode"}==unique_tetrodes_and_mults(i,1) & string(blind_pass_table{:,"Z Score"})==unique_tetrodes_and_mults(i,2),:);
%    plot_units_from_row_of_bp_table(rows_to_plot,colors_map,save_dir,number_to_downsample)
% 
% end
rows_to_plot = blind_pass_table(blind_pass_table{:,"Tetrode"}==unique_tetrodes_and_mults(1,1) & string(blind_pass_table{:,"Z Score"})==unique_tetrodes_and_mults(i,2),:);
plot_sample_channel_data(rows_to_plot,config,fp_to_thresholds_in_mv,colors_map,number_of_dpts_to_plot)

end