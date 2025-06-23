function pcs = get_new_pcs(raw, standard)
%GET_NEW_PCS Computes the principal components for each wire and projects
%each spike onto the best 2
    
    if nargin == 1
        standard = false;
    end
    numwires = size(raw, 1);
    numspikes = size(raw, 2);
    pcs = nan(numwires, numspikes, 2);
    for wire = 1:numwires
        spikes = shiftdim(raw(wire, :, :), 1);
        if standard
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
        pcs(wire, :, :) = score;
    end
end

function colsign = fixsigns(coeff)
    [~,maxind] = max(abs(coeff), [], 1);
    [d1, d2] = size(coeff);
    colsign = sign(coeff(maxind + (0:d1:(d2-1)*d1)));
end