function [area_under_curve,area_over_curve] =get_area_under_zero_line(waveforms,peakWindow)
area_under_curve = nan(size(waveforms,1),size(waveforms,2));
area_over_curve = nan(size(waveforms,1),size(waveforms,2));
for ch = 1:size(waveforms,1)
    for sp = 1:size(waveforms,2)
        w = reshape(waveforms(ch,sp,:),[],1);
        segment = w(peakWindow);

        if any(~isfinite(segment))
            continue
        end

        segment = smoothdata(segment,'sgolay',7);
       
        area_under_curve(ch,sp) = trapz(segment(segment < 0));
        area_under_curve(ch,sp) = trapz(segment(segment > 0));
    end
end
end