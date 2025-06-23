function [maxsnr, amps, snrind] = template_match(spikes, templates)
%TEMPLATE_MATCH Computes a score for how well the spikes match each
%template.
%   [maxsnr, amps, snrind] = TEMPLATE_MATCH(spikes, templates)
%
%   'spikes' are individual waveforms. Assumes spikes have mean removed.
%
%   'templates' are template waveforms.
%
%   'maxsnr' are the statistics for how well the spikes match the best
%   template.
%
%   'amps' are the amplitudes of projections of the spikes onto the
%   templates.
%
%   'snrind' are the indices which produced the max snr.
    
    numdp = size(spikes, 2);
    tl = size(templates, 1);
    ind = bsxfun(@plus, (0:numdp-tl)', 1:tl);
    
    maxsnr = nan(1, size(spikes, 1));
    snrind = maxsnr;
    amps = maxsnr;
    for k = 1:size(spikes, 1)
        x = spikes(k, :);
        V = x(ind);
        S = V * templates;
        A = dot(S, S, 2);
        Err = dot(V, V, 2) - A;
        snr = A ./ Err;
        
        [maxsnr(k), sind] = max(snr);
        amps(k) = A(sind);
        snrind(k) = sind;
    end
end