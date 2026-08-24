function [peakProminence,peakWidthSeconds,peak_width_over_height] = get_peak_prominance_and_peak_width(waveforms,peakWindow)

originalSampleCount = 60;
interpolatedSampleCount = 150;
samplingRate = 30030;
interpolatedStepSeconds = ((originalSampleCount-1)/samplingRate)/(interpolatedSampleCount-1);

[nChannels,nSpikes,~] = size(waveforms);
peakVoltage = nan(nChannels,nSpikes);
peakProminence = nan(nChannels,nSpikes);
peakWidthSeconds = nan(nChannels,nSpikes);
peakIndex = nan(nChannels,nSpikes);
peak_width_over_height = nan(nChannels,nSpikes);;

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

        peak_width_over_height(ch,sp) = peakProminence(ch,sp) ./ peakWidthSeconds(ch,sp);
        peakIndex(ch,sp) = peakWindow(1)+locations(selectedPeak)-1;
    end
end

end