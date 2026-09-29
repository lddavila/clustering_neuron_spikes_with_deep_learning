function should_merge = check_ensemble_merge(left_cluster, right_cluster, ...
        waveforms, timestamps, wire_locations, ensemble_nets, settings)
%CHECK_ENSEMBLE_MERGE Apply the existing cluster-pair merge rules.

should_merge = false;

waveform_difference = waveforms(left_cluster, :) - ...
    waveforms(right_cluster, :);
waveform_distance = sqrt(sum(waveform_difference .^ 2, "all"));
if waveform_distance > settings.waveform_distance_cutoff
    return
end

timestamp_overlap = ...
    find_number_of_true_positives_given_a_time_delta_hpc_using_ptrs( ...
    timestamps{left_cluster}, timestamps{right_cluster}, ...
    settings.time_delta) * 100;
if timestamp_overlap <= settings.timestamp_overlap_cutoff
    return
end

wire_difference = wire_locations(left_cluster, :) - ...
    wire_locations(right_cluster, :);
wire_distance = sqrt(sum(wire_difference .^ 2, "all"));
network_input = [timestamp_overlap, wire_distance, waveform_distance];

for net_id = 1:numel(ensemble_nets)
    scores = predict(ensemble_nets{net_id}, network_input);
    if scores(2) < settings.ensemble_probability_cutoff
        return
    end
end

should_merge = true;
end
