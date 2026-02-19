function [] = plot_overall_unit_grades_for_other_ss(fp_with_agreement_matrices,config)

%get all agreement matrices
table_of_all_files = struct2table(dir(fullfile(fp_with_agreement_matrices,"*","**")));
table_of_all_files.name = string(table_of_all_files.name);
table_of_all_files.folder = string(table_of_all_files.folder);
table_of_all_files(~contains(table_of_all_files.name,"agreement"),:) = [];

all_agreement_tables = cell(height(table_of_all_files),2);
for i=1:height(table_of_all_files)
    recording_dir = table_of_all_files{i,"folder"};

    all_agreement_tables{i,1} = recording_dir;
    all_agreement_tables{i,2} = readtable(fullfile(recording_dir,"agreement_scores.csv"));
end

%create a folder to save all figures and the data to
dir_to_save_figs_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"plot_overall_unit_grades_for_other_ss"));
%declare the different spikesorting methods
different_spike_sorters = ["ironclust","kilosort4","mountainsort4"];

if ~isfile(fullfile(dir_to_save_figs_to,"all_ss_results.mat"))
    %create a container that will keep all the data we wish to modify
    container_with_data = containers.Map('KeyType','char','ValueType','any');

    %get the data results from each spikesorter
    for i=1:length(different_spike_sorters)
        only_current_spike_sorter = all_agreement_tables(contains(string(all_agreement_tables(:,1)),different_spike_sorters(i)),:);

        for j=1:length(only_current_spike_sorter)
            current_table = only_current_spike_sorter{j,2};
            current_agreement_matrix = table2array(current_table(:,2:end));
            recording_info = only_current_spike_sorter{j,1};
            split_recording_info = split(recording_info,filesep);
            only_recording_info = split_recording_info(contains(split_recording_info,"600Neuron300SecondRecordingWithLevel"));
            split_only_recording = split(only_recording_info,"_");
            recording_number = str2double(split_only_recording(1));

            %detect whether or not each column has at least 1 value that is
            %greater than 0.8
            %.8 because kilosort4 uses 0.8 as a way to declare a unit as
            %"detected"
            %so we will use the same standard here
            well_detected_sums = sum(current_agreement_matrix>=0.8,1);
            container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_found_units") = find(well_detected_sums>=1);
            container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_missing_units") = find(well_detected_sums==0);
            container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_number_missing_units") = length(container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_missing_units"));
            container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_number_repititons") = sum(well_detected_sums>1);
            container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_which_repeated")= find(well_detected_sums>1);
            container_with_data(different_spike_sorters(i)+"_recording_"+string(recording_number)+"_MUA_clusters") = find(all(current_agreement_matrix<0.8,2));
        end
    end
    par_save(fullfile(dir_to_save_figs_to,"all_ss_results.mat"),container_with_data);
else
    container_with_data = importdata(fullfile(dir_to_save_figs_to,"all_ss_results.mat"));
end
all_keys = string(keys(container_with_data));
all_keys(~contains(all_keys,"_found_units")) = [];
for i=1:length(all_keys)
    current_key = all_keys(i);
    current_key_wo_end = strrep(current_key,"_found_units","");
    number_of_found = length(container_with_data(current_key_wo_end+"_found_units"));
    number_of_missing = length(container_with_data(current_key_wo_end+"_missing_units"));
    number_of_mua = length(container_with_data(current_key_wo_end+"_MUA_clusters"));

    f = figure('units','normalized','outerposition',[0 0 1 1]);
    tiledlayout(1,2);
    nexttile();
    donutchart([number_of_found,number_of_missing],["number of found","number of missing"]);
    title("Proportion of Units Found out of "+string(number_of_found+number_of_missing)+"units")
    nexttile();
    donutchart([number_of_mua,number_of_found],["fabricated units","non fabricated"]);
    title("Proportion of fabricated to real from "+string(number_of_mua+number_of_found)+" Clusters Detected")
    sgtitle([strrep(current_key_wo_end,"_","\_"), "Need at least 80% accuracy to be detected"]);
    save_plots_in_all_formats(f,fullfile(dir_to_save_figs_to,current_key_wo_end));
    close(f);
end
end