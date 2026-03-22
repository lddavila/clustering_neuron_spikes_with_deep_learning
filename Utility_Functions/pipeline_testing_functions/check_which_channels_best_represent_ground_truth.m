function [table_of_ratios] = check_which_channels_best_represent_ground_truth(dir_with_channel_data,ground_truth_idxs,min_amp)
P_threshold_all = 1:.1:15;
table_of_all_channels = struct2table(dir(fullfile(dir_with_channel_data,"*.mat")));
table_of_all_channels.name = string(table_of_all_channels.name);
table_of_all_channels.folder = string(table_of_all_channels.folder);


% ratio_of_gt_on_channel = zeros(height(table_of_all_channels),length(P_threshold_all));

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(table_of_all_channels) * length(P_threshold_all);
print_status_bar(num_iterations,"check_which_channels_best_represent_ground_truth.m")

table_of_all_permutations =combinations(table_of_all_channels.name,P_threshold_all) ;
table_of_all_permutations.folder = repelem(table_of_all_channels{1,"folder"},size(table_of_all_permutations,1),1);
sliced_table_of_all_channels = slice_table_for_parallel_processing(table_of_all_permutations,["Var1"]);
parfor i=1:height(table_of_all_channels)
    current_data = sliced_table_of_all_channels{i};
    current_channel_data = importdata(fullfile(current_data{1,"folder"},current_data{1,"Var1"}));
    current_channel_data = current_channel_data * -1;
    ratios_for_current_channel = zeros(height(current_data),1);
    all_peak_vals = cell(height(current_data),1);
    all_mean_peak_vals = nan(height(current_data),1);
    all_peak_locs = cell(height(current_data),1)
    for j=1:height(current_data)
        P = struct('spkThresh', [], 'qqFactor', current_data{j,"Var2"});
        [pk_locs,pk_vals,~]= spikeDetectSingle_fast_(current_channel_data,P);
        all_peak_vals{j} = pk_vals;
        all_peak_locs{j} = pk_locs;
        all_mean_peak_vals(j) = mean(pk_vals,"all");
        updated_pk_locs = pk_locs(abs(pk_vals)>min_amp);
        if isempty(updated_pk_locs)
            continue;
        end
        ratios_for_current_channel(j) = (sum(ismembertol(double(round(ground_truth_idxs)), double(round(updated_pk_locs)),6,'DataScale',1)) / numel(ground_truth_idxs)) * 100;
        send(q,[]);
    end
    current_data.ratios_for_current_channel = ratios_for_current_channel;
    current_data.mean_peak_vals = all_mean_peak_vals;
    current_data.all_peak_vals =all_peak_vals;
    
    sliced_table_of_all_channels{i} = current_data;
    
end
table_of_ratios = vertcat(sliced_table_of_all_channels{:});
table_of_ratios = sortrows(table_of_ratios,"ratios_for_current_channel","descend");

end