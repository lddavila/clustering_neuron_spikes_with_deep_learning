function dist = bhat_dist(c1, c2)
%BHAT_DIST Bhattacharyya distance (formula from wikipedia).
%   dist = BHAT_DIST(c1, c2)
    if isempty(c1) || isempty(c2)
        dist = 0;
        return
    end
    mean1 = mean(c1);
    mean2 = mean(c2);
    sigma1 = cov(c1);
    sigma2 = cov(c2);
    sigma = (sigma1 + sigma2)/2;
    sigma_inv = pinv(sigma);
    
    mean_dist = mean1 - mean2;
    t1 = mean_dist * sigma_inv * mean_dist' / 8;
    t2 = log(det(sigma) / sqrt(det(sigma1) * det(sigma2))) / 2;
    dist = t1 + t2;
end
