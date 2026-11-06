%% Unit Tests for Detect Spikes Ver 2
% addpath(genpath()) bypasses folder limitations by adding the whole project to the path
project_dir = fileparts(fileparts(mfilename("fullpath"))); % the folder above tests/
% when sections are run one at a time mfilename can point somewhere else,
% so fall back to the file open in the editor
if ~isfile(fullfile(project_dir,"clustering-master","conf","spikesort_config.m"))
    project_dir = fileparts(fileparts(matlab.desktop.editor.getActiveFilename));
end
addpath(genpath(project_dir));

%% Generate fake recording with different sized spikes
shape = [0.3 0.7 1 0.7 0.3];
raw = zeros(1,2000);
raw(198:202)   = -1.0 * shape;
raw(598:602)   = -0.8 * shape;
raw(998:1002)  = -1.2 * shape;
raw(1398:1402) = -0.9 * shape;
raw(1798:1802) = -1.1 * shape;
raw(1198:1202) = -0.15 * shape;

% add random noise 
rng(0);
raw = raw + 0.03 * randn(size(raw));

% save the recording and its z-scores 
data_dir = tempname;
mkdir(fullfile(data_dir,"recordings"));
mkdir(fullfile(data_dir,"z_score"));
save(fullfile(data_dir,"recordings","c1.mat"),"raw");
channel_wize_z_score_data = zscore(single(raw * -1));
save(fullfile(data_dir,"z_score","c1.mat"),"channel_wize_z_score_data");
rec_dir = fullfile(data_dir,"recordings");
z_dir = fullfile(data_dir,"z_score");


%% Default config (with use_new_spike_detection = false)
previous_dir = cd(project_dir);
default_config = spikesort_config;
cd(previous_dir);
default_config.use_new_spike_detection = false;

%% Unit Test 1: default
disp("Unit Test 1 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 2: same folder as test 1 again (results are reloaded)
disp("Unit Test 2 begun")
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 3: rerun test 1, same folder, different z-score levels
disp("Unit Test 3 begun")
% the saved results from test 1 are returned instead of new ones for [3 5 8]
config.DEFAULT_CLUSTERING_Z_SCORES = [3 5 8];
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 4: higher threshold (min z = 11)
disp("Unit Test 4 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,11,config.SCALE_FACTOR,config)

%% Unit Test 5: lower threshold (min z = 1)
disp("Unit Test 5 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,1,config.SCALE_FACTOR,config)

%% Unit Test 6: scale factor = +1, spikes are negative so they are not found
disp("Unit Test 6 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),1,config)

%% Unit Test 7: z-score levels out of order in config
disp("Unit Test 7 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
config.DEFAULT_CLUSTERING_Z_SCORES = [8 3 5];
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 8: z-score level extremely big
disp("Unit Test 8 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
config.DEFAULT_CLUSTERING_Z_SCORES = [3 5 50];
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 9: max_channel_number bigger than the number of channels
% the default max_channel_number comes from ART_TETR_ARRAY, far more than the 1 channel here
disp("Unit Test 9 begun")
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir; % keeps saved results out of Default_Results_Dir
max_channel_number = config.max_channel_number
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",rec_dir,z_dir,min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 10: same spikes in a different order (smallest first)
disp("Unit Test 10 begun")
raw = zeros(1,2000);
raw(198:202) = -0.8 * shape;
raw(598:602) = -0.9 * shape;
raw(998:1002) = -1.0 * shape;
raw(1398:1402) = -1.1 * shape;
raw(1798:1802) = -1.2 * shape;
raw(1198:1202) = -0.15 * shape;
rng(0);
raw = raw + 0.03 * randn(size(raw));
data_dir = tempname;
mkdir(fullfile(data_dir,"recordings"));
mkdir(fullfile(data_dir,"z_score"));
save(fullfile(data_dir,"recordings","c1.mat"),"raw");
channel_wize_z_score_data = zscore(single(raw * -1));
save(fullfile(data_dir,"z_score","c1.mat"),"channel_wize_z_score_data");
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir;
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",fullfile(data_dir,"recordings"),fullfile(data_dir,"z_score"),min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)

%% Unit Test 11: same spikes but wider (41 samples instead of 5)
disp("Unit Test 11 begun")
wide_shape = 1 - abs(-20:20)/20;
raw = zeros(1,2000);
raw(180:220) = -1.0 * wide_shape;
raw(580:620) = -0.8 * wide_shape;
raw(980:1020) = -2.0 * wide_shape;
raw(1380:1420) = -0.9 * wide_shape;
raw(1780:1820) = -1.1 * wide_shape;
raw(1180:1220) = -0.15 * wide_shape;
rng(0);
raw = raw + 0.03 * randn(size(raw));
data_dir = tempname;
mkdir(fullfile(data_dir,"recordings"));
mkdir(fullfile(data_dir,"z_score"));
save(fullfile(data_dir,"recordings","c1.mat"),"raw");
channel_wize_z_score_data = zscore(single(raw * -1));
save(fullfile(data_dir,"z_score","c1.mat"),"channel_wize_z_score_data");
spikes_dir = tempname; mkdir(spikes_dir);
config = default_config;
config.BLIND_PASS_DIR_PRECOMPUTED = spikes_dir;
[thresholds,locs,amps] = detect_spikes_ver_2(spikes_dir,"c1.mat",fullfile(data_dir,"recordings"),fullfile(data_dir,"z_score"),min(config.DEFAULT_CLUSTERING_Z_SCORES),config.SCALE_FACTOR,config)
