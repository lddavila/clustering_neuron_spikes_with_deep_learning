%edited by Luis David Davila and Alexander Friedman
function the_dist = bhat_dist(the_c1, the_c2)
%BHAT_DIST Bhattacharyya distance (formula from wikipedia).
%   dist = BHAT_DIST(c1, c2)
    if isempty(the_c1) || isempty(the_c2)
        the_dist = 0;
        return
    end
    mean1 = mean(the_c1);
    mean2 = mean(the_c2);
    sigma1 = cov(the_c1);
    sigma2 = cov(the_c2);
    sigma = (sigma1 + sigma2)/2;
    sigma_inv = pinv(sigma);
    
    mean_dist = mean1 - mean2;
    t1 = mean_dist * sigma_inv * mean_dist' / 8;
    t2 = log(det(sigma) / sqrt(det(sigma1) * det(sigma2))) / 2;
    the_dist = t1 + t2;
end
