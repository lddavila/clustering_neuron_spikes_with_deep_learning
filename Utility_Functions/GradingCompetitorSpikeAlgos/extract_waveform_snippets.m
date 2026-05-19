function tetrode_snippets = extract_waveform_snippets( ...
                                tetrode_spike_times, timestamps, ...
                                rec_data, art_tetr_array, window)
%EXTRACT_WAVEFORM_SNIPPETS  Cut voltage snippets around each spike for
%   every tetrode.
%
%   tetrode_snippets{t} is [nSpikes x 4 x (2*window+1)]

num_tetrodes   = numel(tetrode_spike_times);
snippet_length = 2*window + 1;
tetrode_snippets = cell(num_tetrodes, 1);

for t = 1:num_tetrodes

    spike_times_t = tetrode_spike_times{t};

    if isempty(spike_times_t)
        tetrode_snippets{t} = zeros(0, 4, snippet_length);
        continue;
    end

    % Map spike times to nearest sample indices
    spike_sample_indices = interp1(timestamps, 1:length(timestamps), ...
                                   spike_times_t, 'nearest');

    % Remove spikes too close to recording edges
    valid_mask           = spike_sample_indices > window & ...
                           spike_sample_indices <= length(timestamps) - window;
    spike_sample_indices = spike_sample_indices(valid_mask);

    nSpikes  = length(spike_sample_indices);
    snippets = zeros(nSpikes, 4, snippet_length);

    % Get the 4 channel traces for this tetrode
    channels = art_tetr_array(t, :);
    c = cell(4,1);
    for ch_pos = 1:4
        c{ch_pos} = rec_data.(['c' num2str(channels(ch_pos))]);
    end

    % Cut snippets
    for i = 1:nSpikes
        idx = spike_sample_indices(i);
        for ch_pos = 1:4
            snippets(i, ch_pos, :) = c{ch_pos}(idx-window : idx+window);
        end
    end

    tetrode_snippets{t} = snippets;

end