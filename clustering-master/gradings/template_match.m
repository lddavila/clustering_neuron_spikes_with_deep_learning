%updated by Luis David Davila and Alexander Friedman
function [the_maxsnr, the_amps, the_snrind] = template_match(the_spikes, the_templates)
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
    
    numdp = size(the_spikes, 2);
    tl = size(the_templates, 1);
    ind = bsxfun(@plus, (0:numdp-tl)', 1:tl);
    
    the_maxsnr = nan(1, size(the_spikes, 1));
    the_snrind = the_maxsnr;
    the_amps = the_maxsnr;
    for k = 1:size(the_spikes, 1)
        x = the_spikes(k, :);
        V = x(ind);
        S = V * the_templates;
        A = dot(S, S, 2);
        Err = dot(V, V, 2) - A;
        snr = A ./ Err;
        
        [the_maxsnr(k), sind] = max(snr);
        the_amps(k) = A(sind);
        the_snrind(k) = sind;
    end
end