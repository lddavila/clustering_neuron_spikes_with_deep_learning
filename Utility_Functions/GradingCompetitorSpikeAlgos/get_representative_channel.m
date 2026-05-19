function rep_channel = get_representative_channel(templates)
%GET_REPRESENTATIVE_CHANNEL  Find the channel with the largest absolute
%   peak amplitude for every template.
%
%   rep_channel = GET_REPRESENTATIVE_CHANNEL(templates)
%
%   Input
%   -----
%   templates : [nTemplates x nTimepoints x nChannels]  (single or double)
%       Raw template waveforms as loaded from templates.npy.
%
%   Output
%   ------
%   rep_channel : [nTemplates x 1]  integer array (1-based MATLAB indices)
%       rep_channel(k) is the channel index whose waveform has the
%       largest absolute peak for template k.
%
%   Notes
%   -----
%   • Kilosort template numbering is 0-based (0 … nTemplates-1).
%     rep_channel uses 1-based indexing consistent with MATLAB.
%     When comparing against Kilosort cluster IDs, subtract 1 from the
%     MATLAB template index but NOT from rep_channel itself.
%   • The "best" channel is defined as the channel whose waveform has
%     the highest max(abs(waveform)), capturing both positive and
%     negative spike shapes.

%% ── Input validation ─────────────────────────────────────────────────────
validateattributes(templates, {'numeric'}, {'nonempty','ndims',3}, ...
    'get_representative_channel', 'templates');

[nTemplates, ~, nChannels] = size(templates);
assert(nChannels > 0, 'templates has zero channels.');
assert(nTemplates > 0, 'templates has zero templates.');

%% ── Compute representative channel ──────────────────────────────────────
rep_channel = zeros(nTemplates, 1, 'uint32');

for t = 1:nTemplates
    % W : [nTimepoints x nChannels]
    W = squeeze(templates(t, :, :));

    % Maximum absolute value across time for each channel
    peak_per_channel = max(abs(W), [], 1);   % 1 x nChannels

    % Channel with the largest absolute peak  (1-based MATLAB index)
    [~, best_ch] = max(peak_per_channel);
    rep_channel(t) = best_ch;
end

rep_channel = double(rep_channel);

fprintf('    [get_representative_channel] Done. %d templates processed, channels range: %d - %d\n', ...
        nTemplates, min(rep_channel), max(rep_channel));

end