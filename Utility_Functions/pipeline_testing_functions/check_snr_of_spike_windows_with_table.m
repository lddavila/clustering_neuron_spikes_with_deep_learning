function [config,tetrode_level_snr,tetrode_level_recall,tetrode_level_f1,tetrode_level_precision] = check_snr_of_spike_windows_with_table(config,spike_windows,varargin)

ground_truth_cell_array = config.ground_truth_cell_array;
tetr_or_ch_string = config.tetrode;
parent_dir =create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.dir_to_save_debug_files_to,"new_snr"));

multiplier_or_z_sc = config.which_thresh;



table_of_best_rep = config.table_of_best_rep;
save_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(parent_dir,tetr_or_ch_string));

sub_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(save_dir,"mult_"+string(multiplier_or_z_sc)));

save_name = fullfile(sub_dir,string("stage_"+string(config.stage_counter)+".mat"));


%okay now that we have our save dir set up we can check the locations of
%the peaks in spike windows against each item in the cell array
tol_amount = 3; %equiavlent to about .1 milliseconds
detection_ratio_after_dict_creation = zeros(height(table_of_best_rep),1);
snr_ratio = zeros(height(table_of_best_rep),1);
snr_raw = zeros(height(table_of_best_rep),1);
raw_signal_count = zeros(height(table_of_best_rep),1);
tetrode_level_recall = zeros(height(table_of_best_rep),1);
% tetrode_level_precision = zeros(height(table_of_best_rep),1);
% tetrode_level_f1 = zeros(height(table_of_best_rep),1);
tetrode_signal_counts = 0;
spike_windows_mask = zeros(size(spike_windows,1),1);
for i=1:height(table_of_best_rep)
    current_ground_truth_idxs = ground_truth_cell_array{table_of_best_rep{i,"unit"}};
    [is_tp,loc_in_sw] = ismembertol(double(round(current_ground_truth_idxs)), double(round(spike_windows)),tol_amount,'DataScale',1);
    temp_sw_mask = spike_windows_mask;
    temp_sw_mask(loc_in_sw(loc_in_sw~=0)) = 1;
    spike_windows_mask = spike_windows_mask | temp_sw_mask;
    detection_ratio_after_dict_creation(i) = (sum(is_tp) / length(current_ground_truth_idxs))*100;
    snr_raw(i) = (sum(is_tp) / size(spike_windows,1))*100;
    snr_ratio(i) = detection_ratio_after_dict_creation(i) / snr_raw(i);
    raw_signal_count(i) = sum(is_tp);
    tetrode_signal_counts = tetrode_signal_counts+raw_signal_count(i);

    
    tetrode_level_recall(i) = min([raw_signal_count(i),length(current_ground_truth_idxs)]) / length(current_ground_truth_idxs);
    
end
% no_matching_unit_count = size(spike_windows,1) - min([tetrode_signal_counts,size(spike_windows,1)]);

tetrode_level_precision= raw_signal_count ./ (sum(~spike_windows_mask) +  raw_signal_count + eps);
tetrode_level_f1 = 2 .* ((tetrode_level_precision .* tetrode_level_recall) ./ (tetrode_level_precision + tetrode_level_recall));
tetrode_level_snr = (tetrode_signal_counts / size(spike_windows,1)) * 100;
if any(tetrode_level_recall < 0 | tetrode_level_recall > 1)
    disp("something went wrong with recall");
elseif any(tetrode_level_precision < 0 | tetrode_level_precision >1)
    disp("something went wrong with precision");
elseif tetrode_level_f1 < 0 || tetrode_level_f1 > 1
    disp("something went wrong with f_1");
end
if isempty(varargin)
    table_of_best_rep.("detection_ratio_stage_"+string(config.stage_counter)) = detection_ratio_after_dict_creation;
    table_of_best_rep.("raw_snr_stage_"+string(config.stage_counter)) = snr_raw;
    table_of_best_rep.("ratio_snr_stage_"+string(config.stage_counter)) = snr_ratio;
    table_of_best_rep.("raw_signal_count_stage_"+string(config.stage_counter)) = raw_signal_count;
    table_of_best_rep.("spike_windows_size_stage_"+string(config.stage_counter)) = repelem(size(spike_windows,1),height(table_of_best_rep),1);
else
    table_of_best_rep.("detection_ratio_stage_"+string(config.stage_counter)+"prc_"+string(varargin{1})) = detection_ratio_after_dict_creation;
    table_of_best_rep.("raw_snr_stage_"+string(config.stage_counter)+"prc_"+string(varargin{1})) = snr_raw;
    table_of_best_rep.("ratio_snr_stage_"+string(config.stage_counter)+"prc_"+string(varargin{1})) = snr_ratio;
    table_of_best_rep.("raw_signal_count_stage_"+string(config.stage_counter)+"prc_"+string(varargin{1})) = raw_signal_count;
    table_of_best_rep.("spike_windows_size_stage_"+string(config.stage_counter)+"prc_"+string(varargin{1})) = repelem(size(spike_windows,1),height(table_of_best_rep),1);
end
par_save(save_name,table_of_best_rep);
config.table_of_best_rep = table_of_best_rep;

end