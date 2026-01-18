function run_spike_window_check_for_all_available_units(recording_name,loaded_table,table)
%% set up paths
current_script_file_path = mfilename('fullpath');
[current_file_path,~,~] = fileparts(current_script_file_path);
cd(current_file_path);
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
for i = 1:600
    rec_1_specified_unit_table = rec1_table(rec1_table.Max_Overlap_Unit==i,:);
    [~,idx] = max(rec_1_specified_unit_table.accuracy);
    max_accuracy_row_for_specified_unit = rec_1_specified_unit_table(idx,:);
    unit_tetrode = max_accuracy_row_for_specified_unit.Tetrode;
    tetrode_num = str2double(extractAfter(unit_tetrode,1));
    unit_channels = tetrode(tetrode_num,:);
        % Build file paths for each unit channel
    if ~isempty(unit_channels)    
    file_paths = arrayfun(@(ch) ...
        fullfile( ...
            config.base_file_path, ...
            "Default_Results_Dir", ...
            recording_name, ...
            "spike_windows min_z_score 3 num dps 60", ...
            sprintf("c%d.mat", ch)), ...
        unit_channels, ...
        'UniformOutput', false);
    
    % Check if all files exist
    if all(cellfun(@(fp) exist(fp, 'file') == 2, file_paths))
        % ---- Your code here ----
        find_gt_unit_spike_window_overlap_for_specified_unit(i,recording_name,1,full_bp_table)
    end
    end
end