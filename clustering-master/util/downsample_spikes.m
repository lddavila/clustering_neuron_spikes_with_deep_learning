function downsampled = downsample_spikes(s, num_original, ir, config)
%SMOOTH_DATA Interpolates each spike with cubic splines
    [numwires, numspikes, numdp] = size(s);
    
    smoothrange = linspace(1, config.NUM_SMOOTH_POINTS, num_original);
    lastidx = length(smoothrange);
    downsampled = nan(numwires, numspikes, lastidx);
    
    chunksize = 250;
    for wire = 1:numwires
        waves = shiftdim(s(wire, :, :), 1)';
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
%         smoothwaves(smoothwaves > 0.99*ir(wire)) = 0.99*ir(wire);
        downsampled(wire, :, :) = smoothwaves';
    end
end