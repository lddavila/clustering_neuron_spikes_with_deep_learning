function find_gt_unit_spike_window_overlap_for_specified_unit(unit_number,recording_name,loaded_table,table)
%% set up paths
current_script_file_path = mfilename('fullpath');
[current_file_path,~,~] = fileparts(current_script_file_path);
cd(current_file_path);
cd ..
cd ..
addpath(genpath(pwd));
config = spikesort_config;
tetrode = build_artificial_tetrode;
%% load and filter bp table 
if loaded_table==1
    full_bp_table = table;
else
    full_bp_table = importdata(fullfile(config.base_file_path,"Data","all_recordings_table.mat"));
end
rec1_table = full_bp_table(full_bp_table.recording_name==recording_name ,["Z Score","Tetrode","Cluster","Max_Overlap_Unit","accuracy","cluster_idx"]);
% for i = 1:600
%     rec_1_specified_unit_table = rec1_table(rec1_table.Max_Overlap_Unit==i,:);
%     [~,idx] = max(rec_1_specified_unit_table.accuracy);
%     max_accuracy_row_for_specified_unit = rec_1_specified_unit_table(idx,:);
%     unit_tetrode = max_accuracy_row_for_specified_unit.Tetrode;
%     tetrode_num = str2double(extractAfter(unit_tetrode,1));
%     unit_channels = tetrode(tetrode_num,:);
%     if tetrode_num == 1 | tetrode_num == 7
%         disp(i)
%     end
% end
rec_1_specified_unit_table = rec1_table(rec1_table.Max_Overlap_Unit==unit_number,:);
[~,idx] = max(rec_1_specified_unit_table.accuracy);
max_accuracy_row_for_specified_unit = rec_1_specified_unit_table(idx,:);

%% get best tetrode number for unit
unit_tetrode = max_accuracy_row_for_specified_unit.Tetrode;
tetrode_num = str2double(extractAfter(unit_tetrode,1));
unit_channels = tetrode(tetrode_num,:);

%% import spike windows and combine them
fp_to_spike_window_first_channel = fullfile(config.base_file_path,"Default_Results_Dir",recording_name,"spike_windows min_z_score 3 num dps 60",sprintf("c%d.mat",unit_channels(:,1)));
fp_to_spike_window_second_channel = fullfile(config.base_file_path,"Default_Results_Dir",recording_name,"spike_windows min_z_score 3 num dps 60",sprintf("c%d.mat",unit_channels(:,2)));
fp_to_spike_window_third_channel = fullfile(config.base_file_path,"Default_Results_Dir",recording_name,"spike_windows min_z_score 3 num dps 60",sprintf("c%d.mat",unit_channels(:,3)));
fp_to_spike_window_fourth_channel = fullfile(config.base_file_path,"Default_Results_Dir",recording_name,"spike_windows min_z_score 3 num dps 60",sprintf("c%d.mat",unit_channels(:,4)));
first_channel_spike_windows = importdata(fp_to_spike_window_first_channel);
second_channel_spike_windows = importdata(fp_to_spike_window_second_channel);
third_channel_spike_windows = importdata(fp_to_spike_window_third_channel);
fourth_channel_spike_windows = importdata(fp_to_spike_window_fourth_channel);
combined_spike_windows = vertcat(first_channel_spike_windows,second_channel_spike_windows,third_channel_spike_windows,fourth_channel_spike_windows);
combined_spike_windows_peak = combined_spike_windows(:,4);

%% import ground truth
ground_truth = importdata(config.GT_FP);
ground_truth_unit = ground_truth{unit_number};
ground_truth_unit = ground_truth_unit+1;
ground_truth_unit = double(ground_truth_unit);
%% compare ground truth and spike windows spikes
gt_spikes_kept = ismembertol(ground_truth_unit,combined_spike_windows_peak,0.00001);
gt_spikes_kept_count = sum(gt_spikes_kept);
spikes_kept_accuracy = gt_spikes_kept_count/size(ground_truth_unit,2);
disp(max_accuracy_row_for_specified_unit)
fprintf("%f of the spikes in the ground truth unit were kept\n",spikes_kept_accuracy)
