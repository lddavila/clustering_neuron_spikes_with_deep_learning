function [agreement_scores_dict] = get_agreement_tables_for_other_spike_sorters(config,list_of_spike_sorters,list_of_recordings)

default_res_dir = fullfile(config.base_file_path,"Default_Results_Dir/");
agreement_scores_dict = containers.Map('KeyType','char','ValueType','any');
for i=1:length(list_of_recordings)
    current_recording_dir = fullfile(default_res_dir,list_of_recordings(i)+"_results");
    for j=1:length(list_of_spike_sorters)
        current_spike_sorter_dir = current_recording_dir+list_of_spike_sorters(j);
        agreement_matrix = readmatrix(fullfile(current_spike_sorter_dir,"agreement_scores.csv"));
        list_of_units = strcat("GT_UNIT_",string(1:size(agreement_matrix,2)-1));
        row_names = strcat("Cluster_Number_",string(1:size(agreement_matrix,1)-1));
        agreement_matrix(:,1) = [];
        agreement_matrix(1,:) = [];
        agreement_matrix = agreement_matrix * 100;
        agreement_scores_dict(list_of_recordings(i)+" "+list_of_spike_sorters(j)) = array2table(agreement_matrix,"RowNames",row_names,"VariableNames",list_of_units);
    end
end
end