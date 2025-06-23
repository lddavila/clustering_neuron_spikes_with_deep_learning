function [valleyidx, pkidx] = get_first_valley(d, onlyleft, thresh)
%GET_FIRST_VALLEY Gets the first valley of some distribution
    if nargin == 1
        onlyleft = false;
        thresh = Inf;
    end
    d = d(:)';
    valleyidx = 0;
    valleys = find_peaks(-1 * d);
    valleys = valleys{1};
    pks = find_peaks(d);
    pks = pks{1};
    if isempty(pks) || (~isempty(valleys) && valleys(1) < pks(1))
        pkidx = 1;
    else
        pkidx = pks(1);
    end
    if ~isempty(valleys)
        % Assume pk is 2 std from 0.
%         max_dist = pkidx + (pkidx - 1) * 3;
        idxes = valleys(find(valleys > pkidx, 3, 'first'));
        for k = 1:length(idxes)
            idx = idxes(k);
            if d(idx) < thresh && (onlyleft || ~isempty(find(pks > idx, 1)))
                valleyidx = idx;
                return
            end
        end
    end
end