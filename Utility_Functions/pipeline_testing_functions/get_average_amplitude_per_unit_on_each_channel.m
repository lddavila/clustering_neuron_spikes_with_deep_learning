function [table_of_ratios] = get_average_amplitude_per_unit_on_each_channel(dir_with_channel_data,ground_truth_idxs,tol_amount,varargin)

P_threshold_all = 1:.1:15;
if ~isempty(varargin)
    P_threshold_all = varargin{2};
end
table_of_all_channels = struct2table(dir(fullfile(dir_with_channel_data,"*.mat")));
table_of_all_channels.name = string(table_of_all_channels.name);
table_of_all_channels.folder = string(table_of_all_channels.folder);

if ~isempty(varargin)
    table_of_all_channels(~ismember(table_of_all_channels.name,varargin{1}),:) = [];
end

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
    try
        current_channel_data = importdata(fullfile(current_data{1,"folder"},current_data{1,"Var1"}));
        couldnt_load_channel_data = 0;
        current_channel_data = current_channel_data * -1;
    catch
        disp("Couldn't load the channel data");
        couldnt_load_channel_data = 1;
        % continue;
    end

    ratios_for_current_channel = zeros(height(current_data),1);
    % all_peak_vals = cell(height(current_data),1);
    all_mean_peak_vals = nan(height(current_data),1);
    % all_peak_locs = cell(height(current_data),1);
    equivalent_peaks = cell(height(current_data),1);
    if ~couldnt_load_channel_data
        for j=1:height(current_data)
            P = struct('spkThresh', [], 'qqFactor', current_data{j,"Var2"});
            [pk_locs,pk_vals,~]= spikeDetectSingle_fast_(current_channel_data,P);
            % all_peak_vals{j} = pk_vals;
            % all_peak_locs{j} = pk_locs;

            % updated_pk_locs = pk_locs(abs(pk_vals)>min_amp);
            % if isempty(updated_pk_locs)
            %     continue;
            % end
            [is_tp,loc_in_pk_locs]= ismembertol(double(round(ground_truth_idxs)), double(round(pk_locs)),tol_amount,'DataScale',1);
            %to avoid the misalignment caused by only keeping those not equal
            %to 0 we'll use an additional loop to create the data shape we want
            data_to_store_in_equivalent_peaks = nan(length(is_tp),1);
            for k=1:length(data_to_store_in_equivalent_peaks)
                if is_tp(k) && loc_in_pk_locs(k) ~= 0
                    data_to_store_in_equivalent_peaks(k) = pk_locs(loc_in_pk_locs(k));
                end
            end
            equivalent_peaks{j} = data_to_store_in_equivalent_peaks;
            all_mean_peak_vals(j) = mean(abs(pk_vals(loc_in_pk_locs(loc_in_pk_locs~=0))),"all");
            ratios_for_current_channel(j) = (sum(is_tp) / numel(ground_truth_idxs)) * 100;
            send(q,[]);
        end

    end
    current_data.ratios_for_current_channel = ratios_for_current_channel;
    current_data.mean_peak_vals = all_mean_peak_vals;
    current_data.equivalent_peaks = equivalent_peaks;
    % current_data.all_peak_vals =all_peak_vals;

    sliced_table_of_all_channels{i} = current_data;

end
table_of_ratios = vertcat(sliced_table_of_all_channels{:});
table_of_ratios = sortrows(table_of_ratios,["ratios_for_current_channel","mean_peak_vals"],"descend");

end