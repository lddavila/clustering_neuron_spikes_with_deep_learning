function whiten_filt = whiten(peaks)
    [numspikes, numwires] = size(peaks);
    whiten_filt = true(numspikes, 1);
%     numbins = repmat(32, 1, numwires);
    numbins = round(range(peaks) ./ 10);
    if ~all(numbins > 1) || prod(numbins) > prod([60 60 60 60])
        return
    end
    bins = num2cell(numbins);
    [N, ~, ~, loc] = histcn(peaks, bins{:});
    
    
%     gauss = gauss2d(3);
%     gauss = gauss/sum(gauss);
%     N = convn(N, gauss, 'same');

%     mw = ones(repmat(7, 1, numwires));
    windowsize = ceil(std(peaks) ./ 7);
    if all(windowsize == 1) || prod(windowsize) > prod([10 10 10 10])
        return
    end
    mw = ones(windowsize);
    
    M = convn(N, mw, 'same') ./ convn(double(N > 0), mw, 'same');
    
%     N2 = N(:);
%     N2 = N2(N2>0);
%     m = mean(N2);
    
    loc2 = num2cell(loc, 1);
    inds = sub2ind(size(N), loc2{:});
    ns = N(inds);
    ms = M(inds);
    whiten_filt = (ns > 1 | (ns == 1 & ms > 1)) & ns > 1.25 * ms;
%     whiten_filt = ns > 1.25 * ms;
%     for s = 1:numspikes
%         n = N(loc2{s, :});
%         m = M(loc2{s, :});
%         if n < 1 || n <= 1.25 * m
%             whiten_filt(s) = false;
%         end
%     end
end