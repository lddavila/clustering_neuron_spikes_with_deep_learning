function [blind_pass_table] = add_mean_wf_based_in_std_from_cluster_center(blind_pass_table,config)
%this function will add mean waveforms of the cluster center and increment
%upwards by 0.5 std deviations from the cluster center to 5 standard
%deviations away
%we expect the average waveform of the cluster center to be the cleanest
%and the farthest to be the 

%first make sure the fpths are relevant to host machine
blind_pass_table = update_fpths(blind_pass_table,config);
sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,["Z Score","Tetrode"]);
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = size(blind_pass_table,1);
print_status_bar(num_iterations,"add_mean_wf_based_in_std_from_cluster_center.m")
for i=1:size(sliced_blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};
    num_of_channels = size(current_data{:,"grades"}{1}{49},2);

    try
        cleaned_clusters =load(current_data{1,"fp_to_cleaned_clusters"},"cleaned_clusters");
        cleaned_clusters = cleaned_clusters.cleaned_clusters;
    catch
        disp("Failed to load cleaned clusters file")
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


    all_peaks = get_peaks(aligned, true);
    mean_waveform_cell_array = cell(size(current_data,1),num_of_channels);

    for j=1:length(cleaned_clusters)
        %get cluster center
        cluster_filter = cleaned_clusters{j};
        spikes = aligned(:, cluster_filter, :);
        peaks = all_peaks(:, cluster_filter);

        cluster_center = extract_core(peaks,cluster_filter);
        % Set up the representative wire for the cluster
        for k=1:num_of_channels
            % Set up the representative wire for the cluster
            [~, max_wire] = max(peaks, [], 1);
            poss_wires = unique(max_wire);
            n = histc(max_wire, poss_wires);
            [~, max_n] = max(n);
            compare_wire = poss_wires(max_n);
            peaks(compare_wire,:) = nan;
            mean_waveform = mean(shiftdim(spikes(compare_wire, :, :), 1));
            mean_waveform = mean_waveform - mean(mean_waveform);
            mean_waveform_cell_array{j,k} = mean_waveform;
        end
    end

    for k=1:num_of_channels
        current_data.("waveforms_by_std"+string(k)) = mean_waveform_cell_array(:,k);
    end
    sliced_blind_pass_table{i} = current_data;
    send(q,[]);
end
blind_pass_table = vertcat(sliced_blind_pass_table{:});
end