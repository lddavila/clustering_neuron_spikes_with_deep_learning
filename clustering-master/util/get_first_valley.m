%edited by Luis David Davila and Alexander Friedman
function [the_valleyidx, the_pkidx] = get_first_valley(the_d, the_onlyleft, the_thresh)
%GET_FIRST_VALLEY Gets the first valley of some distribution
    if nargin == 1
        the_onlyleft = false;
        the_thresh = Inf;
    end
    the_d = the_d(:)';
    the_valleyidx = 0;
    valleys = find_peaks(-1 * the_d);
    valleys = valleys{1};
    pks = find_peaks(the_d);
    pks = pks{1};
    if isempty(pks) || (~isempty(valleys) && valleys(1) < pks(1))
        the_pkidx = 1;
    else
        the_pkidx = pks(1);
    end
    if ~isempty(valleys)
        % Assume pk is 2 std from 0.
%         max_dist = pkidx + (pkidx - 1) * 3;
        idxes = valleys(find(valleys > the_pkidx, 3, 'first'));
        for k = 1:length(idxes)
            idx = idxes(k);
            if the_d(idx) < the_thresh && (the_onlyleft || ~isempty(find(pks > idx, 1)))
                the_valleyidx = idx;
                return
            end
        end
    end
end