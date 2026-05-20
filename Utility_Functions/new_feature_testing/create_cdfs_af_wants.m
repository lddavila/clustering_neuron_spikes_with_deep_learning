function [table_of_percentiles] = create_cdfs_af_wants(table_of_best_rep,config,detection_rate,detection_rate_for_unit,varargin)
dir_with_tables = "E:\prc_7_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
table_of_percent_tables = struct2table(dir(fullfile(dir_with_tables,"*_bp_table*")));
table_of_percent_tables.folder = string(table_of_percent_tables.folder);
table_of_percent_tables.name = string(table_of_percent_tables.name);
table_of_percentiles = [];

if isempty(varargin)
    q = parallel.pool.DataQueue;
    afterEach(q,@print_status_bar)
    num_iterations = height(table_of_percent_tables);
    print_status_bar(num_iterations,"create_cdfs_af_wants.m: creating tables")
    parfor i=1:height(table_of_percent_tables)
        try
            current_name = table_of_percent_tables{i,"name"};
            the_local_table = importdata(fullfile(table_of_percent_tables{i,"folder"},current_name));
            prctiles_used = the_local_table.prctile_used;

            the_local_table = the_local_table.blind_pass_table;
            the_local_table.prctiles_used = repmat(prctiles_used,size(the_local_table,1),1);
            table_of_percentiles = [table_of_percentiles;the_local_table];
        catch
            disp("caught");
        end
        send(q,[]);
        % fprintf("Finished %i/%i\n",i,height(table_of_percent_tables))
    end
else
    table_of_percentiles = varargin{1};
end

unique_percentiles = unique(table_of_percentiles.prctiles_used,"rows");
unique_multipliers = unique(table_of_percentiles.Multiplier);
colors = distinguishable_colors(length(unique_multipliers));
x = categorical(join(string(unique_percentiles),"\_",2));
figure;
for i=1:length(unique_multipliers)
    current_multiplier = unique_multipliers(i);
    c1 = table_of_percentiles{:,"Multiplier"} == current_multiplier;
    c4 = table_of_best_rep{:,"all_multiplier_idxs"} == current_multiplier;
    y = zeros(1,length(unique_percentiles));
    for j=1:length(unique_percentiles)
        current_prctile = unique_percentiles(j,:);
        c2 = all(table_of_percentiles{:,"prctiles_used"} == current_prctile, 2);
        current_rows = table_of_percentiles(c1 & c2,:);
        unique_tetrodes = unique(current_rows.Tetrode);
        unique_tetrode_numbers = str2double(strrep(unique_tetrodes,"t",""));
        channels = unique(reshape(config.ART_TETR_ARRAY(unique_tetrode_numbers,:),1,[]));
        c3 = ismember(table_of_best_rep{:,"all_channels"},channels);
        c5 = table_of_best_rep{:,"detection_ratio"} > detection_rate;
        best_rep_sub = table_of_best_rep(c3 & c4 & c5, :);
        [~, idx] = unique(best_rep_sub(:,"unit"), 'first');
        best_rep_sub = best_rep_sub(idx,:);
        all_possible_units_detectable_on_channels = best_rep_sub.unit;
        all_units_detected_on_current_data = current_rows{current_rows{:,"Max_Overlap_perc_With_Unit"}>detection_rate_for_unit,"Max_Overlap_Unit"};
        % units_not_found_in_current_rows = setdiff(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        units_found_in_current_rows = intersect(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        y(j) = length(units_found_in_current_rows) / length(all_possible_units_detectable_on_channels);
        % fprintf("Number of units possibly detectable given multiplier %i and percentiles %s: %i\n",current_multiplier,strjoin(string(current_prctile),"_"),length(all_possible_units_detectable_on_channels))

    end
    % Ensure categories are in the order you want
    x = reordercats(x, join(string(unique_percentiles),"\_",2));



    % Plot the line

    plot(x, y, '-o', 'LineWidth', 2, 'MarkerSize', 6,'DisplayName',"Multiplier "+string(current_multiplier),'Color',colors(i,:));
    hold on;

end
% Labels and title
xlabel('Percentiles of PMV used');
ylabel('Ratio of units found');
title(["Ratio of units found across percentiles Normalized by independent Multipliers",...
    "Min Unit's Detection Ratio for cluster:"+string(detection_rate_for_unit)]);
ylim([0,1]);
legend();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unique_percentiles = unique(table_of_percentiles.prctiles_used,"rows");
unique_multipliers = unique(table_of_percentiles.Multiplier);
x = categorical(join(string(unique_percentiles),"\_",2));
figure;
data_new = [];
for i=1:length(unique_multipliers)
    current_multiplier = unique_multipliers(i);
    c1 = table_of_percentiles{:,"Multiplier"} == current_multiplier;
    % c4 = table_of_best_rep{:,"all_multiplier_idxs"} == current_multiplier;
    y = zeros(1,length(unique_percentiles));
    for j=1:length(unique_percentiles)
        current_prctile = unique_percentiles(j,:);
        c2 = all(table_of_percentiles{:,"prctiles_used"} == current_prctile, 2);
        current_rows = table_of_percentiles(c2 & c1,:);

        rows_for_denominator = table_of_percentiles(c2,:);
        unique_tetrodes = unique(rows_for_denominator.Tetrode);
        unique_tetrode_numbers = str2double(strrep(unique_tetrodes,"t",""));
        channels = unique(reshape(config.ART_TETR_ARRAY(unique_tetrode_numbers,:),1,[]));
        c3 = ismember(table_of_best_rep{:,"all_channels"},channels);
        c5 = table_of_best_rep{:,"detection_ratio"} > detection_rate;
        best_rep_sub = table_of_best_rep(c3 & c5, :);
        [~, idx] = unique(best_rep_sub(:,"unit"), 'first');
        best_rep_sub = best_rep_sub(idx,:);
        all_possible_units_detectable_on_channels = best_rep_sub.unit;
        all_units_detected_on_current_data = current_rows{current_rows{:,"Max_Overlap_perc_With_Unit"}>detection_rate_for_unit,"Max_Overlap_Unit"};
        % units_not_found_in_current_rows = setdiff(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        units_found_in_current_rows = intersect(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        y(j) = length(units_found_in_current_rows) / length(all_possible_units_detectable_on_channels);
        % fprintf("Number of units possibly detectable given multiplier %i and percentiles %s: %i\n",current_multiplier,strjoin(string(current_prctile),"_"),length(all_possible_units_detectable_on_channels))

    end
    % Ensure categories are in the order you want
    x = reordercats(x, join(string(unique_percentiles),"\_",2));



    % Plot the line

    plot(x, y, '-o', 'LineWidth', 2, 'MarkerSize', 6,'DisplayName',"Multiplier "+string(current_multiplier),'Color',colors(i,:));
    hold on;
    data_new = [data_new;y];

end
% Labels and title
xlabel('Percentiles of PMV used');
ylabel('Ratio of units found');
title(["Ratio of units found across percentiles Normalized by Max # of Units Detectable Regardless of Multiplier: Total # of possible units found:",length(all_possible_units_detectable_on_channels),...
    "Min Unit's Detection Ratio for cluster:"+string(detection_rate_for_unit)]);
ylim([0,1]);
legend();


f = figure;
x = categorical(string(unique_multipliers));
x = reordercats(x, string(unique_multipliers));
prc_colors = distinguishable_colors(size(unique_percentiles,1));
for i=1:size(unique_percentiles,1)
    plot(x.', data_new(:,i), '-o', 'LineWidth', 2, 'MarkerSize', 6,'DisplayName',"percentile "+strjoin(string(unique_percentiles(i,:)),"\_"),'Color',prc_colors(i,:));
    hold on;
    legend()
end
xlabel("Multiplier")
ylabel("Ratio of detection")
title("Multipliers plot")
close all;
% get the cdfs closer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_tetrodes_for_denominator = unique(table_of_percentiles.Tetrode);
unique_tetrode_numbers = str2double(strrep(all_tetrodes_for_denominator,"t",""));
channels_for_denominator = unique(reshape(config.ART_TETR_ARRAY(unique_tetrode_numbers,:),1,[]));

c3_fixed = ismember(table_of_best_rep{:,"all_channels"},channels_for_denominator);
c5_fixed = table_of_best_rep{:,"detection_ratio"} > detection_rate;

best_rep_fixed = table_of_best_rep(c3_fixed & c5_fixed,:);
[~, idx] = unique(best_rep_fixed(:,"unit"), 'first');
best_rep_fixed = best_rep_fixed(idx,:);

all_possible_units_fixed = best_rep_fixed.unit;
unique_percentiles = unique(table_of_percentiles.prctiles_used,"rows");
unique_multipliers = unique(table_of_percentiles.Multiplier);
x = categorical(join(string(unique_percentiles),"\_",2));
figure;
data_new = [];
for i=1:length(unique_multipliers)
    current_multiplier = unique_multipliers(i);
    c1 = table_of_percentiles{:,"Multiplier"} == current_multiplier;
    % c4 = table_of_best_rep{:,"all_multiplier_idxs"} == current_multiplier;
    y = zeros(1,length(unique_percentiles));
    set_of_units_found = [];
    for j=1:length(unique_percentiles)
        current_prctile = unique_percentiles(j,:);
        c2 = all(table_of_percentiles{:,"prctiles_used"} == current_prctile, 2);
        current_rows = table_of_percentiles(c2 & c1,:);

        rows_for_denominator = table_of_percentiles(c2,:);
        unique_tetrodes = unique(rows_for_denominator.Tetrode);
        unique_tetrode_numbers = str2double(strrep(unique_tetrodes,"t",""));
        channels = unique(reshape(config.ART_TETR_ARRAY(unique_tetrode_numbers,:),1,[]));
        c3 = ismember(table_of_best_rep{:,"all_channels"},channels);
        c5 = table_of_best_rep{:,"detection_ratio"} > detection_rate;
        best_rep_sub = table_of_best_rep(c3 & c5, :);
        [~, idx] = unique(best_rep_sub(:,"unit"), 'first');
        best_rep_sub = best_rep_sub(idx,:);
        all_possible_units_detectable_on_channels = best_rep_sub.unit;
        all_units_detected_on_current_data = current_rows{current_rows{:,"Max_Overlap_perc_With_Unit"}>detection_rate_for_unit,"Max_Overlap_Unit"};
        % units_not_found_in_current_rows = setdiff(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        units_found_in_current_rows = intersect(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        set_of_units_found = union(set_of_units_found,units_found_in_current_rows);
        y(j) = length(set_of_units_found) / length(all_possible_units_fixed);
        % fprintf("Number of units possibly detectable given multiplier %i and percentiles %s: %i\n",current_multiplier,strjoin(string(current_prctile),"_"),length(all_possible_units_detectable_on_channels))

    end
    % Ensure categories are in the order you want
    x = reordercats(x, join(string(unique_percentiles),"\_",2));



    % Plot the line

    plot(x, y, '-o', 'LineWidth', 2, 'MarkerSize', 6,'DisplayName',"Multiplier "+string(current_multiplier),'Color',colors(i,:));
    hold on;
    data_new = [data_new;y];

end
xlabel('Percentiles of PMV used');
ylabel('Ratio of units found');
title("CDF Plot of % of total units found as we vary the percentiles")
ylim([0,1]);
legend();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_tetrodes_for_denominator = unique(table_of_percentiles.Tetrode);
unique_tetrode_numbers = str2double(strrep(all_tetrodes_for_denominator,"t",""));
channels_for_denominator = unique(reshape(config.ART_TETR_ARRAY(unique_tetrode_numbers,:),1,[]));

c3_fixed = ismember(table_of_best_rep{:,"all_channels"},channels_for_denominator);
c5_fixed = table_of_best_rep{:,"detection_ratio"} > detection_rate;

best_rep_fixed = table_of_best_rep(c3_fixed & c5_fixed,:);
[~, idx] = unique(best_rep_fixed(:,"unit"), 'first');
best_rep_fixed = best_rep_fixed(idx,:);

all_possible_units_fixed = best_rep_fixed.unit;
unique_percentiles = unique(table_of_percentiles.prctiles_used,"rows");
unique_multipliers = unique(table_of_percentiles.Multiplier);
x = categorical(string(unique_multipliers));
x = reordercats(x, string(unique_multipliers));
figure;
data_new = [];
prc_colors = distinguishable_colors(length(unique_percentiles));
for i=1:size(unique_percentiles,1)
    current_prctile = unique_percentiles(i,:);
    c1 =all(table_of_percentiles{:,"prctiles_used"} == current_prctile, 2); 
    % c4 = table_of_best_rep{:,"all_multiplier_idxs"} == current_multiplier;
    y = zeros(1,length(unique_multipliers));
    set_of_units_found = [];
    for j=1:length(unique_multipliers)
        current_multiplier = unique_multipliers(j);
        c2 = table_of_percentiles{:,"Multiplier"} == current_multiplier;
        current_rows = table_of_percentiles(c2 & c1,:);

        rows_for_denominator = table_of_percentiles(c1,:);
        unique_tetrodes = unique(rows_for_denominator.Tetrode);
        unique_tetrode_numbers = str2double(strrep(unique_tetrodes,"t",""));
        channels = unique(reshape(config.ART_TETR_ARRAY(unique_tetrode_numbers,:),1,[]));
        c3 = ismember(table_of_best_rep{:,"all_channels"},channels);
        c5 = table_of_best_rep{:,"detection_ratio"} > detection_rate;
        best_rep_sub = table_of_best_rep(c3 & c5, :);
        [~, idx] = unique(best_rep_sub(:,"unit"), 'first');
        best_rep_sub = best_rep_sub(idx,:);
        all_possible_units_detectable_on_channels = best_rep_sub.unit;
        all_units_detected_on_current_data = current_rows{current_rows{:,"Max_Overlap_perc_With_Unit"}>detection_rate_for_unit,"Max_Overlap_Unit"};
        % units_not_found_in_current_rows = setdiff(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        units_found_in_current_rows = intersect(all_possible_units_detectable_on_channels,all_units_detected_on_current_data);
        set_of_units_found = union(set_of_units_found,units_found_in_current_rows);
        y(j) = length(set_of_units_found) / length(all_possible_units_fixed);
        % fprintf("Number of units possibly detectable given multiplier %i and percentiles %s: %i\n",current_multiplier,strjoin(string(current_prctile),"_"),length(all_possible_units_detectable_on_channels))

    end
    plot(x, y, '-o', 'LineWidth', 2, 'MarkerSize', 6,'DisplayName',"percentile "+strjoin(string(unique_percentiles(i,:)),"\_"),'Color',prc_colors(i,:));
    hold on;

end
xlabel('Multiplier');
ylabel('Ratio of units found');
title("CDF Plot of % of total units found as we vary the percentiles")
ylim([0,1]);
legend();
end