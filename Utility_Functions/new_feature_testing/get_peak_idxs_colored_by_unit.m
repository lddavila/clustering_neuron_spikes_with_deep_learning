function [unit_idx,new_colors,unit_list] = get_peak_idxs_colored_by_unit(config,peaks,varargin)
table_of_best_rep = importdata(config.fp_to_ch_to_units);
if isempty(varargin)
    channels = config.current_channels;
else
    channels = varargin{1};
end
unit_idx = {};
ground_truth = config.ground_truth_cell_array;
unit_colors = distinguishable_colors(length(ground_truth));
peaks = peaks(1:length(config.current_channels),:);
sw = config.mutated_sw;
new_colors = [];
unit_list = [];
just_detection= [];
for i=1:length(channels)
    only_curr_ch = sortrows(table_of_best_rep(table_of_best_rep{:,"all_channels"}==channels(i) & table_of_best_rep{:,"all_multiplier_idxs"}==config.which_thresh,:),"detection_ratio_stage_1","descend");
    % only_curr_ch = table_of_best_rep;
    unique_units = unique(only_curr_ch{only_curr_ch.detection_ratio_stage_1>20,"unit"});
    % sw_for_curr_channel = sw(sw(:,3)==channels(i),4);
    tol_amount = 2;
    for j=1:length(unique_units)
        current_unit_peak_locs = ground_truth{unique_units(j)};
        new_colors = [new_colors;unit_colors(unique_units(j),:)];

        [is_tp,loc_in_sw_for_curr_channel]= ismembertol(double(round(current_unit_peak_locs)), double(round(sw(:,4))),tol_amount,'DataScale',1);
        detection_rate = (sum(is_tp)/length(current_unit_peak_locs)) * 100;
        just_detection = [just_detection;detection_rate];
        unit_list = [unit_list;string(unique_units(j))+sprintf(" det rate %.2f",detection_rate)];
        unit_idx{end+1} = loc_in_sw_for_curr_channel(loc_in_sw_for_curr_channel~=0);
    end
end
[b,i] = sort(just_detection,"descend");

the_end = min([length(i),10]);
unit_idx = unit_idx(i(1:the_end));
new_colors = new_colors(i(1:the_end),:);
unit_list = unit_list(i(1:the_end));

end