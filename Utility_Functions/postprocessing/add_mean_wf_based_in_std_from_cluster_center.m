function [blind_pass_table] = add_mean_wf_based_in_std_from_cluster_center(blind_pass_table,config)
%this function will add mean waveforms of the cluster center and increment
%upwards by 0.5 std deviations from the cluster center to 3.5 standard
%deviations away
%we expect the average waveform of the cluster center to be the cleanest
%and the farthest to be the 

%first make sure the fpths are relevant to host machine
% blind_pass_table = update_fpths(blind_pass_table,config);

%if the blind pass is a mix of multiple recordings then we also have to
%slice the data on that level as well
if ~ismember(blind_pass_table.Properties.VariableNames,"recording_name")
    sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode"]);
else
    sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode","recording_name"]);
end
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(blind_pass_table,1);
print_status_bar(num_iterations,"add_mean_wf_based_in_std_from_cluster_center.m")
parfor i=1:size(sliced_blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};
    num_of_channels = size(current_data{:,"grades"}{1}{49},2);

    try
        cleaned_clusters =load(current_data{1,"fp_to_cleaned_clusters"},"cleaned_clusters");
        cleaned_clusters = cleaned_clusters.cleaned_clusters;
    catch
        % disp("Failed to load cleaned clusters file")
        disp(current_data{1,"fp_to_cleaned_clusters"})
        send(q,[]);
        continue;
    end
    try
        aligned = importdata(current_data{1,"fp_to_aligned"});
        aligned = aligned.aligned;
    catch
        disp("Failed to load aligned file")
        disp(current_data{1,"fp_to_aligned"})
        send(q,[]);
        continue;
    end


    num_std = 0:0.5:3.5;

    all_peaks = get_peaks(aligned, true);
    mean_waveform_cell_array = cell(size(current_data,1),num_of_channels,length(num_std));

    for j=1:length(cleaned_clusters)
        %get cluster center
        cluster_filter = cleaned_clusters{j};
        spikes = aligned(:, cluster_filter, :);
        peaks = all_peaks(:, cluster_filter);
        % cluster_center = extract_core(all_peaks.',cluster_filter,config.spikesort);

        cluster_mean = mean(peaks,2);
        cluster_std = std(peaks,[],2);
        % cluster_center_max = max(all_peaks(:,cluster_center),[],2);

        % Set up the representative wire for the cluster

        for k=1:num_of_channels
            % Set up the representative wire for the cluster
            [~, max_wire] = max(peaks, [], 1);
            poss_wires = unique(max_wire);
            n = histc(max_wire, poss_wires);
            [~, max_n] = max(n);
            compare_wire = poss_wires(max_n);
            

            %now here we have to cycle through the standard deviations of
            %the cluster data
            %at 0 num_std we will calculate the mean of the waveform only
            %based on the cluster center
            %we'll slowly expand the standard and include more of the
            %cluster as we progress
            % legend_strings = repelem("",length(num_std));
            for std_counter=1:length(num_std)
                if j==1 && k==2
                    disp("Something edge case")
                end
                %by default the idxs will ALWAYS include the cluster core
                %idxs_to_build_mean_wf_from = cluster_center;

                %now determine which additional peaks can be added
                upper_bound_cond = cluster_mean(compare_wire) + (num_std(std_counter) * cluster_std(compare_wire));
                all_idxs = peaks(compare_wire,:)<=upper_bound_cond;

                if sum(all_idxs) == 1
                    %edge case to keep the value from collapsing into a 1x1
                    %matrix
                    mean_waveform_cell_array{j,k,std_counter} = shiftdim(spikes(compare_wire, all_idxs, :)).';
                else
                    %now we need to add any idxs that
                    mean_waveform = mean(shiftdim(spikes(compare_wire, all_idxs, :), 1));
                    mean_waveform = mean_waveform - mean(mean_waveform);
                    mean_waveform_cell_array{j,k,std_counter} = mean_waveform;
                    % plot(mean_waveform)
                    % legend_strings(std_counter) =sprintf("# std dvns outside cluster: %.2f",num_std(std_counter)) ;
                    % hold on;

                end

                
            end
            % legend(legend_strings)
            peaks(compare_wire,:) = nan;
        end
    end


    for k=1:num_of_channels
        cell_array_of_waveforms_by_std = cell(size(current_data,1),1);
        for j=1:size(current_data,1)
            % fprintf("k:%i j:%i\n",k,j);
            cell_array_of_waveforms_by_std{j} = cell2mat(squeeze(mean_waveform_cell_array(j,k,:)));
        end
        current_data.("waveforms_by_std_"+string(k)) = cell_array_of_waveforms_by_std;
    end
    sliced_blind_pass_table{i} = current_data;
    send(q,[]);
end
blind_pass_table = vertcat(sliced_blind_pass_table{:});
end