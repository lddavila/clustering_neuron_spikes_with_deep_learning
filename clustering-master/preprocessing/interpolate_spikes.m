function interp_raw = interpolate_spikes(raw, config)
%INTERPOLATE_SPIKES Interpolates each spike using cubic splines.
%   interp_raw = INTERPOLATE_SPIKES(raw)
    [numwires, numspikes, numdp] = size(raw);
    
    smoothrange = linspace(1, numdp, config.NUM_SMOOTH_POINTS);
    lastidx = length(smoothrange);
    interp_raw = nan(numwires, numspikes, lastidx);
    
    chunksize = 250;
    for wire = 1:numwires
        waves = squeeze(raw(wire, :, :))';
        smoothwaves = interp1(1:numdp, waves, smoothrange);
%         numchunks = floor(numspikes/chunksize);
%         remainchunk = mod(numspikes, chunksize);
%         smoothwaves = nan(numspikes, lastidx);
%         for chunk=1:numchunks
%             chunkrange = (chunk-1)*chunksize + 1:chunk*chunksize;
%             smoothwaves(chunkrange, :) = spline(1:numdp, waves(chunkrange, :), smoothrange);
%         end
%         if remainchunk > 0
%             chunkrange = numchunks*chunksize + 1:numchunks*chunksize + remainchunk;
%             smoothwaves(chunkrange, :) = spline(1:numdp, waves(chunkrange, :), smoothrange);
%         end
        interp_raw(wire, :, :) = smoothwaves';
    end
end