function overlaps = compute_overlaps(sets1, sets2)
%COMPUTE_OVERLAPS Computes set overlaps in both directions
    overlaps = nan(length(sets1), length(sets2), 2);
    for c1 = 1:length(sets1)
        set1 = sets1{c1};
        for c2 = 1:length(sets2)
            set2 = sets2{c2};
            overlap = intersect(set1, set2);
            overlap_len = length(overlap);
            overlaps(c1, c2, 1) = overlap_len/length(set1);
            overlaps(c1, c2, 2) = overlap_len/length(set2);
        end
    end
end