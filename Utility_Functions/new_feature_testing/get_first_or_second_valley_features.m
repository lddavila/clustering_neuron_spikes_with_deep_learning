function [peakProminence,peakWidthSeconds,peakVoltage] = get_first_or_second_valley_features(waveforms,peakWindow)

%depending on the window these features will either have to do with the 1st
%valley (before datapoint 47 where the spike is guaranteed to be) or the
%2nd valley (after datapoint 47) 


originalSampleCount = 60;
interpolatedSampleCount = 150;
samplingRate = 30030;
interpolatedStepSeconds = ((originalSampleCount-1)/samplingRate)/(interpolatedSampleCount-1);

[nChannels,nSpikes,~] = size(waveforms);
peakVoltage = nan(nChannels,nSpikes);
peakProminence = nan(nChannels,nSpikes);
peakWidthSeconds = nan(nChannels,nSpikes);
peakIndex = nan(nChannels,nSpikes);

for ch = 1:nChannels
    for sp = 1:nSpikes
        w = reshape(waveforms(ch,sp,:),[],1);
        segment = w(peakWindow);

        if any(~isfinite(segment))
            continue
        end

        segment = smoothdata(segment,'sgolay',7);
        [peakValues,locations,widths,prominences] = findpeaks(segment,'WidthReference','halfprom');

        if isempty(peakValues)
            continue
        end

        [~,selectedPeak] = max(prominences);
        peakVoltage(ch,sp) = peakValues(selectedPeak);
        peakProminence(ch,sp) = prominences(selectedPeak);
        peakWidthSeconds(ch,sp) = widths(selectedPeak)*interpolatedStepSeconds;
        peakIndex(ch,sp) = peakWindow(1)+locations(selectedPeak)-1;
    end
end

end