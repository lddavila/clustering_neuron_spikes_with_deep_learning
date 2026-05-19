%% set the path
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir)
%% get the config and set tetrodes we want to use & get their channels
config = spikesort_config;
art_tetr_array = config.ART_TETR_ARRAY;
tetrodes_to_use = [1,2,3];
channels_to_use = unique(art_tetr_array(tetrodes_to_use,:));
%% get the data we need for the channels we want to test
lower_ch = get_which_units_appear_on_specified_channels(channels_to_use,"C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\Recording 10 Units Representation On Channels");

%% get list of units which are found on the lower_ch
units_on_lower_ch = unique(lower_ch{:,"unit"});
%% get the tables which will contain the accuracy data we need
%test_table = get_all_accuracy_tables_from_testing("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\tables_from_testing_percentiles_and_multipliers");
test_table = get_all_accuracy_tables_from_testing("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\tables_from_testing_percentiles_and_multipliers_2");

%% remove rows from test table that aren't part of the desired tetrodes
test_table(~ismember(test_table{:,"Tetrode"},strcat("t",string(tetrodes_to_use))), :) = [];
%% get list of units which are found on the test tables
units_found_by_test_tables = unique(test_table{:,"Max_Overlap_Unit"});
%% see which units are in common
units_in_both = intersect(units_found_by_test_tables,units_on_lower_ch);
%% display them
disp("units in both: "+string(length(units_in_both.')))
disp(units_in_both.')
disp("only in lower ch"+string(length(setdiff(units_on_lower_ch,units_in_both).')))
disp(setdiff(units_on_lower_ch,units_in_both).')
disp("only in test tables"+string(length(setdiff(units_found_by_test_tables,units_in_both))))
disp(setdiff(units_found_by_test_tables,units_in_both).')

%% get a max overlap unit that appears all all the tetrodes in test table
list_of_max_overlap_units = unique(test_table{:,"Max_Overlap_Unit"});
unique_tetrodes = unique(test_table{:,"Tetrode"});
for i=1:length(unique_tetrodes)
    current_rows = test_table(test_table{:,"Tetrode"}==unique_tetrodes(i),:);
    list_of_max_overlap_units = intersect(list_of_max_overlap_units,current_rows{:,"Max_Overlap_Unit"});
end
%% upload all the aligned files
% cell_array_of_aligned = cell(length(unique_tetrodes),1);
% dir_with_aligned_files = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\aligned_files_for_tetrodes_for_rec_10";
% for i=1:length(cell_array_of_aligned)
%     cell_array_of_aligned{i} = importdata(fullfile(dir_with_aligned_files,unique_tetrodes(i)+" aligned.mat")).aligned;
%
% end
%% import some timestamps
timestamps = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\1_600Neuron300SecondRecordingWithLevel1Noise\timestamps\timestamps.mat");
%% now let's try seeing if the cluster on 1 tetrode can be split by looking at other dimensions
tol_amount = 6;
dir_with_aligned_files = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\aligned_files_for_tetrodes_for_rec_10";
dir_with_dictionaries = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\Spike Windows & spike files";
config.ground_truth_cell_array = importdata("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat");
config.has_ground_truth = 1;
config.debug_with_ground_truth = 1;
config.GT_FP = "C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Data\10_600Neuron300SecondRecordingWithLevel10Noise\ground_truth\ground_truth.mat";
debug_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"plots_for_test_tinkering_around_phase"));
dir_to_save_debug_files_to = debug_dir;
config.current_table_of_best_rep = lower_ch;
config.plot_counter = 1;
config.which_subset = 1;
clc;
close all;
for i=1:length(list_of_max_overlap_units)
    current_unit = list_of_max_overlap_units(i);
    c1 = test_table{:,"Max_Overlap_Unit"}==current_unit;
    for j=1:length(unique_tetrodes)
        current_tetrode = unique_tetrodes(j);
        c2 = test_table{:,"Tetrode"} == current_tetrode;
        current_data_from_test = test_table(c1 & c2,:);


        %pick the one with the highest accuracy
        [max_val,max_idx] = max(current_data_from_test{:,"accuracy"});
        best_representative = current_data_from_test(max_idx,:);

        best_rep_aligned_file = fullfile(dir_with_aligned_files,current_tetrode+"_aligned_mult"+string(best_representative{1,"Multiplier"})+"_prc_"+strjoin(string(best_representative.prctiles_used),"_")+".mat");
        aligned = importdata(best_rep_aligned_file);
        the_peaks = get_peaks(aligned,true).';



        cf_1 = best_representative{1,"cluster_idx"}{1};
        c1_peaks = the_peaks(cf_1,:);
        current_channels =art_tetr_array(str2double(strrep(best_representative{1,"Tetrode"},"t","")),:);
        [rep_wire,rep_channel] = calculate_the_rep_wire(c1_peaks.',current_channels);
        best_representative.channels = current_channels;
        config.current_channels = current_channels;
        % best_representative.fp_to_aligned =
        sw_file = fullfile(dir_with_dictionaries,current_tetrode+" sorted_spike_windows.mat");
        current_sw = importdata(sw_file);
        current_sw = current_sw.sorted_spike_windows_for_current_tetrode_dictionary;
        current_sw = current_sw(current_tetrode);
        for k=j+1:length(unique_tetrodes)
            compare_tetrode = unique_tetrodes(k);
            c3 = test_table{:,"Tetrode"}== compare_tetrode;
            compare_data_from_test = test_table(c1 & c3,:);
            compare_data_from_test.channels = repmat(art_tetr_array(str2double(strrep(compare_data_from_test{1,"Tetrode"},"t","")),:),height(compare_data_from_test),1);

            for z=1:height(compare_data_from_test)
                cf_2 = compare_data_from_test{z,"cluster_idx"}{1};

                % compare_aligned_file = fullfile(dir_with_aligned_files,compare_tetrode+"_aligned_mult"+string(compare_data_from_test{z,"Multiplier"})+"_prc_"+strjoin(string(compare_data_from_test{z,"prctiles_used"}),"_")+".mat");
                compare_spikes_file = fullfile(dir_with_dictionaries,compare_tetrode+" spike_tetrode_dictonary.mat");
                compare_sw_file = fullfile(dir_with_dictionaries,compare_tetrode+" sorted_spike_windows.mat");

                try
                    compare_spikes = importdata(compare_spikes_file);
                    compare_spikes = compare_spikes.spike_tetrode_dictionary;
                    compare_spikes = compare_spikes(compare_tetrode);
                    compare_sw = importdata(compare_sw_file);
                    compare_sw = compare_sw.sorted_spike_windows_for_current_tetrode_dictionary;
                    compare_sw = compare_sw(compare_tetrode);
                catch
                    continue;
                end

                interp_comp_spikes = interpolate_spikes(compare_spikes,config);
                cluster_2_aligned = align_to_peak(interp_comp_spikes);
                cluster_2_peaks = get_peaks(cluster_2_aligned,true).';
                c2_peaks = cluster_2_peaks(cf_2,:);
                % overlap = get_overlap_percentage_between_2_cluster_ts(best_representative{1,"timestamps"}{1},compare_data_from_test{z,"timestamps"}{1},config) * 100;
                % group_clusters = check_mergability_for_2_clusters_using_group_or_dont_nn(c1_peaks,c2_peaks,cf_1,cf_2,aligned,config,length(overlap),min([length(cf_1),length(cf_2)]),cluster_2_aligned,compare_data_from_test{z,"channels"});
                %if the clusters are mergable by the neural networks then
                %we'll see if the cluster which looks like 1 on the current
                %tetrode can be split if we were to add different
                %dimensions of data

                group_clusters = 1;
                if group_clusters
                    %find where the spikes for the current cluster appear
                    %on the compare tetrode
                    compare_spike_times = timestamps(compare_sw(:,4));
                    [loc_of_ts_on_compare_tetrode,which_spikes_belong_to_current_unit] = ismembertol(best_representative{1,"timestamps"}{1},compare_spike_times,config.TIME_DELTA ,'DataScale',1);


                    config.mutated_spike_windows = current_sw;
                    config.tetrode = current_tetrode;

                    % best_representative.aligned = {aligned};
                    
                    
                    plot_row_of_bp_table(best_representative,aligned,config);

                    
                    temp_row = compare_data_from_test(z,:);

                    temp_row.cluster_idx = {find(loc_of_ts_on_compare_tetrode)};

                    % temp_row.aligned = {cluster_2_aligned};
                    config.mutated_spike_windows = compare_sw;
                    config.current_tetrode = compare_tetrode;
                    config.plot_counter = config.plot_counter+1;
                    plot_row_of_bp_table(temp_row,cluster_2_aligned,config);
                    config.plot_counter = config.plot_counter+1;
                else
                end
                fprintf("i:%i j:%i k:%i z:%i\n",i,j,k,z)
            end
        end
    end
end