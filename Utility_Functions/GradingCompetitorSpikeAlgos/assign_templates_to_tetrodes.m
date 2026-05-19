function tetrode_template_ids = assign_templates_to_tetrodes( ...
                                    rep_channel, art_tetr_array)
%ASSIGN_TEMPLATES_TO_TETRODES  Group Kilosort template IDs by tetrode.
%
%   tetrode_template_ids = ASSIGN_TEMPLATES_TO_TETRODES(rep_channel,
%                                                        art_tetr_array)
%
%   Inputs
%   ------
%   rep_channel    : [nTemplates x 1] integer (1-based MATLAB channel idx)
%       Representative channel for each template, as returned by
%       get_representative_channel().
%
%   art_tetr_array : [nTetrodes x 4] integer (1-based channel indices)
%       Each row lists the 4 channels that form one tetrode.
%
%   Output
%   ------
%   tetrode_template_ids : {nTetrodes x 1} cell array of column vectors
%       tetrode_template_ids{t} contains the 0-based Kilosort cluster IDs
%       whose representative channel belongs to tetrode t.
%       Empty cell entries indicate tetrodes with no matching templates.
%
%   Notes
%   -----
%   • Kilosort cluster IDs are 0-based.  Because rep_channel is 1-based,
%     the cluster ID for MATLAB index k is  k - 1.
%   • Templates whose representative channel does not appear in any
%     tetrode are silently excluded.  A per-tetrode coverage report is
%     printed at the end.

%% ── Input validation ─────────────────────────────────────────────────────
validateattributes(rep_channel, {'numeric'}, ...
    {'nonempty','vector','integer','positive'}, ...
    'assign_templates_to_tetrodes', 'rep_channel');

validateattributes(art_tetr_array, {'numeric'}, ...
    {'nonempty','2d','ncols',4,'integer','positive'}, ...
    'assign_templates_to_tetrodes', 'art_tetr_array');

rep_channel = rep_channel(:);          % ensure column vector
num_tetrodes = size(art_tetr_array, 1);

%% ── Assign templates to tetrodes ─────────────────────────────────────────
tetrode_template_ids = cell(num_tetrodes, 1);

for t = 1:num_tetrodes
    tetrode_channels = art_tetr_array(t, :);   % 1 x 4

    % Logical mask: which templates have their rep channel on this tetrode
    on_tetrode = ismember(rep_channel, tetrode_channels);

    if ~any(on_tetrode)
        % No templates assigned to this tetrode – leave cell empty
        tetrode_template_ids{t} = zeros(0, 1, 'uint32');
        continue;
    end

    % find() gives 1-based MATLAB template indices → subtract 1 for
    % 0-based Kilosort cluster IDs
    matlab_indices  = find(on_tetrode);           % 1-based
    kilosort_ids    = uint32(matlab_indices - 1); % 0-based

    tetrode_template_ids{t} = kilosort_ids;
end

%% ── Summary report ───────────────────────────────────────────────────────
n_assigned   = cellfun(@numel, tetrode_template_ids);
n_with_units = sum(n_assigned > 0);
total_assigned = sum(n_assigned);

fprintf(['    [assign_templates_to_tetrodes] %d / %d tetrodes have at ' ...
         'least one template.\n'], n_with_units, num_tetrodes);
fprintf(['    [assign_templates_to_tetrodes] %d templates assigned in ' ...
         'total (out of %d).\n'], total_assigned, numel(rep_channel));

unassigned = numel(rep_channel) - total_assigned;
if unassigned > 0
    fprintf(['    [assign_templates_to_tetrodes] WARNING: %d template(s) ' ...
             'not matched to any tetrode channel.\n'], unassigned);
end
end
