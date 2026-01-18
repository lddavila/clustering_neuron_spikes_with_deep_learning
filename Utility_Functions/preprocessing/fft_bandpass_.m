% 10/15/2018 JJJ: Modified from ms_bandpass_filter (MountainLab) 
function filt = fft_bandpass_(N, freqLim, freqLim_width, sRateHz)
%N = 131672 N is the length of the channel data
%freqLim =[300 6000] 
%some magic numbers, seem to not matter though cause
%they can be set to nan
%freqLim_width =[ 100 1000]
%more magic numbers
%sRateHz = 25000
%sampling rate in hertz it seems
% Usage
% [Y, filt] = bandpass_fft_(X, freqLim, freqLim_width, sRateHz)
% [filt] = 
% sRateHz: sampling rate
% freqLim: frequency limit, [f_lo, f_hi]
% freqLim_width: frequency transition width, [f_width_lo, f_width_hi]
if isempty(freqLim), freqLim = [nan, nan]; end
[f_lo, f_hi] = deal(freqLim(1), freqLim(2));
if f_lo==0 || isinf(f_lo), f_lo = nan; end
if f_hi==0 || isinf(f_hi), f_hi = nan; end

[fwid_lo, fwid_hi] = deal(freqLim_width(1), freqLim_width(2));

[n1, n2, f] = get_freq_(N, sRateHz);

if ~isnan(f_lo) && ~isnan(f_hi)
    filt = sqrt((1+erf((abs(f)-f_lo)/fwid_lo)) .* (1-erf((abs(f)-f_hi)/fwid_hi)))/2;
elseif ~isnan(f_lo) && isnan(f_hi)
    filt = sqrt((1+erf((abs(f)-f_lo)/fwid_lo))/2);
elseif ~isnan(f_hi) && isnan(f_lo)
    filt = sqrt((1-erf((abs(f)-f_hi)/fwid_hi))/2);
else
    filt = [];
end
end %func