function [all_valley_levels] = get_valley(aligned)
all_valley_levels = nan(size(aligned,1),size(aligned,2));
for channelIndex=1:size(aligned,1)
    W = squeeze(aligned(channelIndex,:,:));
    template = median(W,1,'omitnan');
    template = smoothdata(template,'sgolay',9);
    peakIndex = 48;
    edgeMargin = 10;
    postSearchWindow = peakIndex+8:size(W,2)-edgeMargin;
    [~,relativeIndex] = min(template(postSearchWindow));
    templateValleyIndex = postSearchWindow(relativeIndex);
    localRadius = 8;
    valleyIndex = nan(size(W,1),1);
    valleyAmplitude = nan(size(W,1),1);
    valleyLevel = nan(size(W,1),1);
    fixedValleyWindow = max(postSearchWindow(1),templateValleyIndex-localRadius):min(postSearchWindow(end),templateValleyIndex+localRadius);

    for sp = 1:size(W,1)
        localWaveform = smoothdata(W(sp,fixedValleyWindow),'sgolay',7);
        [~,localMinimum] = min(localWaveform);
        candidateIndex = fixedValleyWindow(localMinimum);
        amplitudeWindow = max(1,candidateIndex-2):min(size(W,2),candidateIndex+2);
        valleyIndex(sp) = candidateIndex;
        valleyAmplitude(sp) = mean(W(sp,amplitudeWindow),'omitnan');
        valleyLevel(sp) = median(W(sp,fixedValleyWindow),'omitnan');
        if candidateIndex == fixedValleyWindow(1) || candidateIndex == fixedValleyWindow(end)
            valleyIndex(sp) = NaN;
            valleyAmplitude(sp) = NaN;
        end
    end
    all_valley_levels(channelIndex,:) = valleyLevel ;
end