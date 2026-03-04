%edited by Luis David Davila and Alexander Friedman
function the_pcs = get_new_pcs(the_raw, the_standard)
%GET_NEW_PCS Computes the principal components for each wire and projects
%each spike onto the best 2
    
    if nargin == 1
        the_standard = false;
    end
    numwires = size(the_raw, 1);
    numspikes = size(the_raw, 2);
    the_pcs = nan(numwires, numspikes, 2);
    for wire = 1:numwires
        spikes = shiftdim(the_raw(wire, :, :), 1);
        if the_standard
            sigma = cov(spikes);
        else
            n_spikes = bsxfun(@minus, spikes, mean(spikes, 2));
            sigma = n_spikes' * n_spikes;% / size(spikes, 1);
        end
        [C, ~] = eig(sigma);
        coeff = C(:, [end, end-1]);
        colsign = fixsigns(coeff);
        score = spikes * coeff;
        score = bsxfun(@times, score, colsign);
        the_pcs(wire, :, :) = score;
    end
end

function colsign = fixsigns(coeff)
    [~,maxind] = max(abs(coeff), [], 1);
    [d1, d2] = size(coeff);
    colsign = sign(coeff(maxind + (0:d1:(d2-1)*d1)));
end