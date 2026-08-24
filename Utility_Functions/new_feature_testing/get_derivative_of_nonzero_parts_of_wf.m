function [derivative,validRanges] = get_derivative_of_nonzero_parts_of_wf(aligned)

originalSampleCount = 60;
interpolatedSampleCount = 150;
originalStepsPerInterpolatedStep = (originalSampleCount-1)/(interpolatedSampleCount-1);

[nChannels,nSpikes,nSamples] = size(aligned);
derivative = nan(nChannels,nSpikes,nSamples-1,'like',aligned);
validRanges = cell(nChannels,1);

for ch = 1:nChannels
    ranges = [];

    for sp = 1:nSpikes
        w = reshape(aligned(ch,sp,:),[],1);
        nz = find(isfinite(w) & w ~= 0);

        if isempty(nz)
            continue
        end

        firstSample = nz(1);
        lastSample = nz(end);
        ranges(end+1,:) = [sp,firstSample,lastSample];

        if lastSample > firstSample
            dw = diff(w(firstSample:lastSample))/originalStepsPerInterpolatedStep;
            derivative(ch,sp,firstSample:lastSample-1) = reshape(dw,1,1,[]);
        end
    end

    validRanges{ch} = ranges;
end

end