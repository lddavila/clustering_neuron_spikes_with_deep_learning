function [viSpk1, vrSpk1, thresh1] = spikeDetectSingle_fast_(vrWav1, P, thresh1) %LOOK AT THIS HERE
%vrWav1 seems to be channel data
% vrWav1 can be either single or int16
% P: spkThresh, qqSample, qqFactor, fGpu, uV_per_bit
%P is a struct that has data that can be used, but if not provided then a
%local P struct will be constructed to use
%thresh1 is the threshold for spikes
%if not provided then it will be computed

% 6/27/17 JJJ: bugfix: hard set threshold is applied

% Determine threshold
MAX_SAMPLE_QQ = 2^16; %300000; 
% fSpikeRefrac_site = 0;
if nargin < 3, thresh1 = []; end
if nargin < 2, P = struct('spkThresh', [], 'qqFactor', 5); end
if ~isempty(get_(P, 'spkThresh')), thresh1 = P.spkThresh; end

if thresh1==0, [viSpk1, vrSpk1] = deal([]); return; end % bad site
%calculate the the threshold
if isempty(thresh1)  
    vr_ = subsample_vr_(vrWav1, MAX_SAMPLE_QQ); 
    %a random subset of the channel data
    thresh1 = median(abs(vr_ - median(vr_))); vr_=[];
    %the Median Absolute Deviation
    %shows how dispered the data is around the dataset median
    %kind of like cv
%     thresh1 = median(abs(subsample_vr_(vrWav1, MAX_SAMPLE_QQ)));
    thresh1 = single(thresh1)* P.qqFactor / 0.6745;
    %P.qqFactor is 5 by default we'll need to see if it needs to be
    %specially calculated or not 
    %0.6745 seems to be a magic number, don't know where it comes from
end
%cast the threshold to match the channel data
thresh1 = cast(thresh1, 'like', vrWav1); % JJJ 11/5/17

% detect valley turning point. cannot detect bipolar
% pick spikes crossing at least three samples
nneigh_min = get_set_(P, 'nneigh_min_detect', 0);  %set the nneigh_min_detect to 0 in the struct p and return 0 once the param is set
viSpk1 = find_peak_(vrWav1, min(thresh1), nneigh_min);  
if get_set_(P, 'fDetectBipolar', 0) %if you want spikes on both sides run the detection again, but flip polarity
   viSpk1 = [viSpk1; find_peak_(-vrWav1, min(thresh1), nneigh_min)]; %append the spikes
   viSpk1 = sort(viSpk1); %sort the spikes
end
if isempty(viSpk1)
    viSpk1 = double([]);
    vrSpk1 = int16([]);
else
    vrSpk1 = vrWav1(viSpk1);
    % Remove spikes too large
    spkThresh_max_uV = get_set_(P, 'spkThresh_max_uV', []);
    if ~isempty(spkThresh_max_uV)
        thresh_max1 = abs(spkThresh_max_uV) / get_set_(P, 'uV_per_bit', 1);
        thresh_max1 = cast(thresh_max1, 'like', vrSpk1);
        viA1 = find(abs(vrSpk1) < abs(thresh_max1));
        viSpk1 = viSpk1(viA1);
        vrSpk1 = vrSpk1(viA1); 
    end        
end

% if isGpu_(viSpk1)
%     [viSpk1, vrSpk1, thresh1] = multifun_(@gather, viSpk1, vrSpk1, thresh1);
% end
end %func