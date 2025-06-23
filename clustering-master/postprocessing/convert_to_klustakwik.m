function convert_to_klustakwik(filename, output_filename)
    filename = regexprep(filename, '^~', getenv('HOME'));
    config = spikesort_config();
    raw = [];
    try
        raw = extract_raw(filename, config);
    catch
    end
    if isempty(raw)
        disp('Error extracting spikes')
        return
    end
    numwires = size(raw, 1);
    numspikes = size(raw, 2);
    pcs = nan(numwires, numspikes, 3);
    for wire = 1:numwires
        spikes = shiftdim(raw(wire, :, :), 1);
        sigma = cov(spikes);
        [C, ~] = eig(sigma);
        coeff = C(:, [end, end-1, end-2]);
        colsign = fixsigns(coeff);
        score = spikes * coeff;
        score = bsxfun(@times, score, colsign);
        pcs(wire, :, :) = score;
    end
    spikes = reshape(permute(pcs, [2, 1, 3]), [numspikes, numwires * 3]);
    
   	f = fopen(output_filename, 'w');
    fprintf(f, '%d\n', numwires * 3);
    for spike = 1:numspikes
        fprintf(f, '%f ', spikes(spike, :));
        fprintf(f, '\n');
    end
    fclose(f);
end

function colsign = fixsigns(coeff)
    [~,maxind] = max(abs(coeff), [], 1);
    [d1, d2] = size(coeff);
    colsign = sign(coeff(maxind + (0:d1:(d2-1)*d1)));
end
