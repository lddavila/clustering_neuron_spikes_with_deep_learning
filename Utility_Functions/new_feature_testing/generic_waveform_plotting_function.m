function [] = generic_waveform_plotting_function(waveforms,varargin)

random_idx = randperm(size(waveforms,2),min([100,size(waveforms,2)]));
for i=1:size(waveforms,1)
    current_waveforms = squeeze(waveforms(i,random_idx,:)).';
    figure;
    tiledlayout("flow");
    nexttile()
    plot(current_waveforms);
    for j=1:2:length(varargin)
        nexttile();
        other_wf = varargin{j};
        other_data = squeeze(other_wf(i,random_idx,:)).';
        plot(other_data);
        title(varargin{j+1});
    end
end
end