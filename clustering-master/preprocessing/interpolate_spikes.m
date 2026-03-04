%edited by Luis David Davila and Alexander Friedman
function the_interp_raw = interpolate_spikes(the_raw, the_config)
%INTERPOLATE_SPIKES Interpolates each spike using cubic splines.
%   interp_raw = INTERPOLATE_SPIKES(raw)
    [numwires, numspikes, numdp] = size(the_raw);
    
    smoothrange = linspace(1, numdp, the_config.NUM_SMOOTH_POINTS);
    lastidx = length(smoothrange);
    the_interp_raw = nan(numwires, numspikes, lastidx);
    
    chunksize = 250;
    for wire = 1:numwires
        waves = squeeze(the_raw(wire, :, :))';
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
        the_interp_raw(wire, :, :) = smoothwaves';
    end
end