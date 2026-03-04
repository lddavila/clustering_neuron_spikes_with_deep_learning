%edited by Luis David Davila and Alexander Friedman
function the_wire_filter = find_live_wires(the_raw)
%FIND_LIVE_WIRES Creates a filter to ignore dead wires.
the_wire_filter = false(1, size(the_raw, 1));
for wire = 1:size(the_raw, 1)
    if sum(any(squeeze(the_raw(wire, :, :)), 2)) > 0.5 * size(the_raw, 2)% OG LINE
    % if sum(any(squeeze(raw(wire, :, :)), 2)) > 0.1 * size(raw, 2)% EDITED LINE
        % The number of nonzero spikes in this wire is more than 50% of
        % the number of spikes in the recording.
        the_wire_filter(wire) = true;
    end
end
end