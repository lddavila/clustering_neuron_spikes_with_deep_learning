%edited by Luis David Davila and Alexander Friedman
function the_overlaps = compute_overlaps(the_sets1, the_sets2)
%COMPUTE_OVERLAPS Computes set overlaps in both directions
    the_overlaps = nan(length(the_sets1), length(the_sets2), 2);
    for c1 = 1:length(the_sets1)
        set1 = the_sets1{c1};
        for c2 = 1:length(the_sets2)
            set2 = the_sets2{c2};
            overlap = intersect(set1, set2);
            overlap_len = length(overlap);
            the_overlaps(c1, c2, 1) = overlap_len/length(set1);
            the_overlaps(c1, c2, 2) = overlap_len/length(set2);
        end
    end
end