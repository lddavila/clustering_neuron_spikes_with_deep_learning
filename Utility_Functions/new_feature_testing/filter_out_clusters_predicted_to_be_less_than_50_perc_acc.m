function [rows_to_keep,filter_mask,estimated_accuracy] = filter_out_clusters_predicted_to_be_less_than_50_perc_acc(blind_pass_table,config,options)
arguments
    blind_pass_table table;
    config struct
    options.make_before_filt_acc_hist = false;
    options.make_after_filt_acc_hist = false;
    options.analyze_failure_cases = false;
    options.where_to_filter_by = 50;
    options.array_of_certainties = [];
    options.create_figures_for_choose_better_poster_panel = false;
    options.dir_to_save_panel_figures_to = "";
    options.only_above_60 = false;
end
if options.dir_to_save_panel_figures_to == "" && options.create_figures_for_choose_better_poster_panel
    options.create_figures_for_choose_better_poster_panel = false;
end
bp_var_names = string(blind_pass_table.Properties.VariableNames);
if ~ismember("accuracy",bp_var_names)
    disp("accuracy is not already computed in your blind pass table so histograms cannot be made")
    disp("Please use ground truth, blind pass table, add_overlap_percentage_col_and_max_overlap_unit_optimized.m,add_accuracy_col.m to add accuracy to your table")
    options.make_before_filt_acc_hist = false;
    options.make_after_filt_acc_hist = false;
    options.analyze_failure_cases = false;
end
dir_with_nets = fullfile(config.base_file_path,"Neural_Networks","prob_dist_nets_temp_scaling_num_channels_var");
table_of_nets = struct2table(dir(fullfile(dir_with_nets,"*.mat")));
table_of_nets.name = string(table_of_nets.name);
table_of_nets.folder = string(table_of_nets.folder);
net_names = split(table_of_nets.name,"_");
table_of_nets.net_num = str2double(net_names(:,3));
table_of_nets = sortrows(table_of_nets,"net_num","ascend");
if isempty(options.array_of_certainties)
    array_of_certainties = zeros(height(blind_pass_table),height(table_of_nets));

    if options.make_before_filt_acc_hist
        figure;
        histogram(blind_pass_table.accuracy,'BinEdges',0:1:100);
        title("Distributions of Accuracy Before Filter")
    end

    old_to_new_cell_array = importdata(fullfile(config.base_file_path,"Neural_Networks","old_to_new_cell_arr_2_and_3_to_4","old_to_new_cell_array_for_4_3_2_channel_padded_to_4.mat"));
    padded_grades = get_all_grades_with_padding(blind_pass_table,config,"predefined_old_to_new_cell_array",old_to_new_cell_array);
    only_ident = blind_pass_table(:,["Z Score","Tetrode","Cluster","which_new_clustering_features"]);

    for i=1:size(array_of_certainties,2)
        %get the net struct and needed attributes for prediction
        net_struct = importdata(fullfile(table_of_nets{i,"folder"},table_of_nets{i,"name"}));
        mu = net_struct.mu;
        sigma = net_struct.sigma;
        layers = net_struct.net;


        new_grades_table = [only_ident,table(padded_grades,'VariableNames',["grades"])];
        rescaled_grades = normalize_the_data(new_grades_table,"mu",mu,"sigma",sigma);
        predictions = predict(layers,rescaled_grades.grades);
        %values closer to 1 indicate very certain it is above threshold i
        %values cloer to -1 indicate very certain it is below threshold i
        array_of_certainties(:,i) = predictions(:,2) - predictions(:,1);
    end
else
    array_of_certainties = options.array_of_certainties;
end
array_of_certainties = smoothdata(array_of_certainties,2,"gaussian");
thresholds = table_of_nets.net_num;
num_clusters = size(array_of_certainties,1);

tol = 0.10;
window = 10;   % Previously 5
required = 3;


estimated_accuracy = nan(num_clusters,1);
reliable_mask = false(num_clusters,1);
rejection_reason = strings(num_clusters,1);

for r = 1:num_clusters
    curve = array_of_certainties(r,:);

    if any(~isfinite(curve))
        rejection_reason(r) = "Nonfinite predictions";
        continue
    end

    % Only consider positive-to-negative crossings.
    candidates = find( ...
        curve(1:end-1) >= 0 & curve(2:end) < 0);

    if isempty(candidates)
        rejection_reason(r) = "No downward crossing";
        continue
    end
    valid_crossings = [];

    for k = candidates
        before = curve(max(1,k-window+1):k);
        after  = curve(k+1:min(numel(curve),k+window));

        if sum(before > tol) >= required && ...
                sum(after < -tol) >= required
            valid_crossings(end+1) = k;
        end
    end

    % Multiple sustained downward crossings remain ambiguous.
    if isempty(valid_crossings)
        rejection_reason(r) = "Insufficient support around crossing";
        continue
    elseif numel(valid_crossings) > 1
        rejection_reason(r) = "Multiple supported crossings";
        continue
    end

    k = valid_crossings(1);

    % Interpolate the zero crossing between adjacent thresholds.
    fraction = curve(k) / (curve(k) - curve(k+1));

    estimated_accuracy(r) = thresholds(k) + fraction * ...
        (thresholds(k+1) - thresholds(k));

    reliable_mask(r) = true;
    rejection_reason(r) = "Accepted";
end
disp(groupcounts(table(rejection_reason),"rejection_reason"))

filter_mask = reliable_mask & ...
    estimated_accuracy >= options.where_to_filter_by;

rows_to_keep = blind_pass_table(filter_mask,:);

if options.make_after_filt_acc_hist
    figure;
    histogram(rows_to_keep.accuracy,'BinEdges',0:1:100);
    title("Distributions of accuracy After Filter")
end

if options.analyze_failure_cases
    faliure_cases = filter_mask ~= logical(blind_pass_table.accuracy >= options.where_to_filter_by);
    for i=1:length(faliure_cases)
        if ~faliure_cases(i)
            continue;
        end
        f = figure;
        bar(array_of_certainties(i,:),'grouped','blue','BarWidth',1);
        xline(blind_pass_table{i,"accuracy"},"LineWidth",5,"Color","green","Label","True accuracy "+sprintf('%.2f',blind_pass_table{i,"accuracy"}))
        if reliable_mask(i)
            xline(estimated_accuracy(i),"LineWidth",5,"Color","red", ...
                "Label","Predicted accuracy "+sprintf('%.2f',estimated_accuracy(i)));
        end
        hold on;
        xlabel("accuracy thresholds 1-100");
        ylabel("Certainty (probability of being above - probability of being below)")
        title("Row "+string(i)+" in blind_pass_table");
        subtitle(strjoin(blind_pass_table{i,["Z Score","Tetrode","Cluster","which_new_clustering_features"]}, " "))
        % disp("press any key to continue");
        close(f);
    end


end

if options.create_figures_for_choose_better_poster_panel
    clc;
    close all;
    if options.only_above_60
        c1 = blind_pass_table{:,"accuracy"} > 70 & estimated_accuracy > 70;
        blind_pass_table(~c1,:) = [];
        estimated_accuracy(~c1) = [];
    end
    for i=1:height(blind_pass_table)
        figure;
        bar(array_of_certainties(i,:),'grouped','blue','BarWidth',1);
        xline(blind_pass_table{i,"accuracy"},"LineWidth",5,"Color","black","Label","True accuracy "+sprintf('%.2f',blind_pass_table{i,"accuracy"}),"LabelHorizontalAlignment","right")
        xline(estimated_accuracy(i),"LineWidth",5,"Color","red","Label","Estimated accuracy "+sprintf('%.2f',estimated_accuracy(i)),"LabelHorizontalAlignment","left")
        xlabel("accuracy thresholds 1-100");
        ylabel("Certainty")
        save_it = input('save? (y/n/cancel) ', 's');
        if save_it=='y'
            format_poster_fig();
            exportgraphics(gcf, fullfile(options.dir_to_save_panel_figures_to, 'certainty_plots_row_'+string(i)+'.pdf'), 'ContentType', 'vector','BackgroundColor','none')
            close all;
        end
        if save_it=="cancel" || save_it == "c"
            break;
        end
        close all;
    end

end
end