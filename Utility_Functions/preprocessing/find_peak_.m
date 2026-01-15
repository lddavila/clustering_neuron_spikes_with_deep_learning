function viSpk1 = find_peak_(vrWav1, thresh1, nneigh_min) %LOOK AT THIS HERE
% nneigh_min: number of neighbors around the spike below the threshold
%  0,1,2. # neighbors of minimum point below negative threshold 
% thresh1: absolute value. searching for negative peaks only

if nargin<3, nneigh_min = []; end
if isempty(nneigh_min), nneigh_min = 1; end

viSpk1 = [];
if isempty(vrWav1), return; end %no data catch
vl1 = vrWav1 < -abs(thresh1); %find where the channel data is less than the computed threshold
vi2 = find(vl1); %get the indexes of the found spikes on the channel data
%vi2 = find(vrWav1 < -thresh1);
if isempty(vi2), return; end %if there are no spikes then return 

if vi2(1)<=1 %something went wrong because they should be whole numbers
    if numel(vi2) == 1, return; end
    vi2(1) = []; 
end    
if vi2(end)>=numel(vrWav1) %something went wrong because there shouldn't be any spikes that appear outside the data limits
    if numel(vi2) == 1, return; end
    vi2(end) = []; 
end
vrWav12 = vrWav1(vi2); %get the peaks of all the spikes
viSpk1 = vi2(vrWav12 <= vrWav1(vi2+1) & vrWav12 <= vrWav1(vi2-1)); %keep only the spikes have no direct neighbors with higher amplitude
if isempty(viSpk1), return; end

switch nneigh_min
    case 1
        viSpk1 = viSpk1(vl1(viSpk1-1) | vl1(viSpk1+1));
    case 2
        viSpk1 = viSpk1(vl1(viSpk1-1) & vl1(viSpk1+1));
end
end %func