function [all_troughs] =get_trough(aligned)

all_troughs = [];
for i=1:size(aligned,1)
    W = squeeze(aligned(i,:,:));
    template = median(W,1,'omitnan');
    template = smoothdata(template,'sgolay',9);
    searchWindow = 5:35;
    [~,relativeIndex] = min(template(searchWindow));
    templateTroughIndex = searchWindow(relativeIndex);
    localRadius = 5;
    troughIndex = nan(size(W,1),1);
    troughAmplitude = nan(size(W,1),1);
    robustTroughLevel = nan(size(W,1),1);

    for sp = 1:size(W,1)
        localWindow = max(searchWindow(1),templateTroughIndex-localRadius):min(searchWindow(end),templateTroughIndex+localRadius);
        localWaveform = smoothdata(W(sp,localWindow),'sgolay',7);
        [~,localMinimum] = min(localWaveform);
        candidateIndex = localWindow(localMinimum);
        amplitudeWindow = max(1,candidateIndex-1):min(size(W,2),candidateIndex+1);
        troughIndex(sp) = candidateIndex;
        troughAmplitude(sp) = mean(W(sp,amplitudeWindow),'omitnan');
        robustTroughLevel(sp) = mean(mink(W(sp,searchWindow),3),'omitnan');
        if candidateIndex == localWindow(1) || candidateIndex == localWindow(end)
            troughIndex(sp) = NaN;
            troughAmplitude(sp) = NaN;
        end
    end
    all_troughs = [all_troughs,troughAmplitude];
end