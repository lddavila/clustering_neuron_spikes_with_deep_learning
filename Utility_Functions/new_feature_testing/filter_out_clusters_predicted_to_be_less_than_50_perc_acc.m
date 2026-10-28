function [rows_to_keep,rows_flagged_for_refinement,rows_to_discard,filter_mask,estimated_accuracy,array_of_certainties_unsmoothed] = filter_out_clusters_predicted_to_be_less_than_50_perc_acc(blind_pass_table,config,options)
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
    options.get_statistics_of_faliures = false;
    options.save_statistics = false;
    options.dir_to_save_statistics_to = "";
    options.look_at_nans = false;
    options.min_distance = 5;
    options.tol = 0.10;
    options.window = 3;   % Previously 5
    options.required = 3;
    options.smoothness_window = 5; % Points on each side of a candidate
    options.distance_between_candidates = 5;
    options.tol_for_mono_inc_dec = .08;
    options.window_for_mono_inc_dec = 5;
    options.smoothing_window_for_mono_inc_dec = 5;
    options.min_support_on_left_for_mono = 3;
    options.min_support_on_right_for_mono = 3;
    options.window_for_polyfit = 5;
    options.make_confusion_matrix_heatmap = false;
    options.edges_for_heatmap = {0:10:100,0:50:100,0:25:100};
    options.uncertainty_window = [40,60];
    options.which_faliures_to_analyze = "all";
end

    function [] = get_statistics_of_faliures(blind_pass_table,options,filter_mask)
        tp_cond = blind_pass_table.accuracy >= options.where_to_filter_by & filter_mask;
        fn_cond = blind_pass_table.accuracy >= options.where_to_filter_by & ~filter_mask;
        fp_cond = blind_pass_table.accuracy < options.where_to_filter_by & filter_mask;
        tn_cond = blind_pass_table.accuracy < options.where_to_filter_by & ~filter_mask;
        tp = sum(tp_cond);%was greater than options.where_to_filter_by & was preserved
        fn = sum(fn_cond);%was greater than options.where_to_filter_by & was NOT preserved
        fp = sum(fp_cond);%was less than options.where_to_filter_by & was preserved WHEN IT SHOULDNT HAVE BEEN
        tn = sum(tn_cond);%was less than options.where_to_filter_by & was NOT PRESERVED (CORRECTLY)
        fprintf("TP: %i TN: %i FP: %i FN: %i\n",tp,tn,fp,fn);

        %now look at the break down of where each tp/fn/fp/tn come from based on distance to options.where_to_filter_by
        distances_to_filter = blind_pass_table.accuracy - options.where_to_filter_by;
        bounds_to_use = -50:5:50;
        tp_log = zeros(length(bounds_to_use)-1,1);
        tn_log = zeros(length(bounds_to_use)-1,1);
        fp_log = zeros(length(bounds_to_use)-1,1);
        fn_log = zeros(length(bounds_to_use)-1,1)+ 1;
        for g=1:length(bounds_to_use)-1

            lower_b = bounds_to_use(g);
            upper_b = bounds_to_use(g+1);
            if g == length(bounds_to_use)-1
                is_in_bound = distances_to_filter >= lower_b & distances_to_filter <= upper_b;
            else
                is_in_bound = distances_to_filter >= lower_b & distances_to_filter < upper_b;
            end
            tp_log(g) = sum(tp_cond & is_in_bound);
            tn_log(g) = sum(tn_cond & is_in_bound);
            fp_log(g) = sum(sum(fp_cond & is_in_bound));
            fn_log(g) = sum(fn_cond & is_in_bound);
            if sum(is_in_bound)==0
                continue;
            end

            fprintf("Boundary %i to %i \n",lower_b,upper_b);
            fprintf("TP:%i\n",tp_log(g));
            fprintf("TN:%i\n",tn_log(g));
            fprintf("FP:%i\n",fp_log(g));
            fprintf("FN:%i\n",fn_log(g));
            disp("///////////////////////")
        end
        total_count = tp_log + tn_log + fp_log + fn_log;
        predicted_positive = tp_log + fp_log;
        actual_positive = tp_log + fn_log;
        f1_denominator = 2 .* tp_log + fp_log + fn_log;

        % Undefined metrics remain NaN
        accuracy_curve  = nan(size(tp_log));
        precision_curve = nan(size(tp_log));
        recall_curve    = nan(size(tp_log));
        f1_curve        = nan(size(tp_log));

        valid = total_count > 0;
        accuracy_curve(valid) = 100 .* (tp_log(valid) + tn_log(valid)) ./ total_count(valid);

        valid = predicted_positive > 0;
        precision_curve(valid) = 100 .* tp_log(valid) ./ predicted_positive(valid);

        valid = actual_positive > 0;
        recall_curve(valid) = 100 .* tp_log(valid) ./ actual_positive(valid);

        valid = f1_denominator > 0;
        f1_curve(valid) = 100 .* (2 .* tp_log(valid)) ./ f1_denominator(valid);

        x_data = string(bounds_to_use(1:end-1)) +" to "+string(bounds_to_use(2:end));
        figure('units','normalized','outerposition',[0 0 1 1]);
        tiledlayout(2,2,"TileSpacing","tight")
        nexttile
        bar(x_data,tp_log,1)
        title("tp")
        nexttile();
        bar(x_data,tn_log,1)
        title("tn")
        nexttile();
        bar(x_data,fp_log,1)
        title("fp")
        nexttile()
        bar(x_data,fn_log,1)
        title("fn")

        % sgtitle("Filter Point At "+string(options.where_to_filter_by)+" "+sprintf("TP: %i TN: %i FP: %i FN: %i\n",tp,tn,fp,fn));
        % if options.save_statistics && options.dir_to_save_statistics_to ~=""
        %     save_plots_in_all_formats(gcf,fullfile(options.dir_to_save_statistics_to,"Filter Point At "+string(options.where_to_filter_by)+".mat"))
        % end

        figure;



        sgtitle("Filter Point At "+string(options.where_to_filter_by)+" "+sprintf("TP: %i TN: %i FP: %i FN: %i\n",tp,tn,fp,fn));


        x_data_as_char = cell(length(x_data),1);
        for g=1:length(x_data)
            x_data_as_char{g} = char(x_data(g));
        end
        categorical_x = categorical(x_data_as_char);
        categorical_x = reordercats(categorical_x,x_data_as_char);
        plot(categorical_x,accuracy_curve,"DisplayName","Accuracy","LineWidth",3,'Marker','o');
        hold on;
        plot(categorical_x,precision_curve,"DisplayName","Precision","LineWidth",3,'Marker','square');
        plot(categorical_x,recall_curve,"DisplayName","Recall",'LineWidth',3,'Marker','*');
        plot(categorical_x,f1_curve,"DisplayName","F1","LineWidth",3,'Marker','diamond');

        xlabel("Distance From Filtering Boundary")
        ylabel("Score")
        legend();
        ylim([0,100]);
        format_poster_fig();
        if options.save_statistics && options.dir_to_save_statistics_to ~=""
            save_plots_in_all_formats(gcf,fullfile(options.dir_to_save_statistics_to,"Line Plots Filter Point At "+string(options.where_to_filter_by)+".mat"))
        end
        legend();
        figure;
        total_count = tp_log + tn_log + fp_log + fn_log;

        retention_curve = nan(size(total_count));
        valid = total_count > 0;

        retention_curve(valid) = 100 .* ...
            (tp_log(valid) + fp_log(valid)) ./ total_count(valid);

        plot(categorical_x,retention_curve,"DisplayName","Retention Rate","LineWidth",3,'Marker','diamond');
        legend;
        if options.save_statistics && options.dir_to_save_statistics_to ~=""
            save_plots_in_all_formats(gcf,fullfile(options.dir_to_save_statistics_to,"Retention Curve Plots Filter Point At "+string(options.where_to_filter_by)+".mat"))
        end
    end

    function analyze_faliure_cases(filter_mask,blind_pass_table,options,array_of_certainties,reliable_mask,estimated_accuracy,rejection_reason,cell_array_of_candidates)
        if lower(options.which_faliures_to_analyze) == "fp"
            failure_cases = logical(blind_pass_table.accuracy <= options.where_to_filter_by) & estimated_accuracy >= options.where_to_filter_by ;
        elseif lower(options.which_faliures_to_analyze) == "fn"
            failure_cases = logical(blind_pass_table.accuracy >= options.where_to_filter_by) & estimated_accuracy <= options.where_to_filter_by;
        end
        
        for g=1:length(failure_cases)
            if ~failure_cases(g)
                continue;
            end
            f = figure;
            bar(array_of_certainties(g,:),'grouped','blue','BarWidth',1);
            xline(blind_pass_table{g,"accuracy"},"LineWidth",5,"Color","green","Label","True accuracy "+sprintf('%.2f',blind_pass_table{g,"accuracy"}))
            if reliable_mask(g)
                xline(estimated_accuracy(g),"LineWidth",5,"Color","red", ...
                    "Label","Predicted accuracy "+sprintf('%.2f',estimated_accuracy(g)));
            end
            hold on;
            xlabel("accuracy thresholds 1-100");
            ylabel("Certainty (probability of being above - probability of being below)")
            title(strrep(strjoin(blind_pass_table{g,["Z Score","Tetrode","Cluster","which_new_clustering_features"]}, " "),"_","\_"));
            subtitle(rejection_reason(g));
            % disp("press any key to continue");
            current_candidates = cell_array_of_candidates{g};
            if ~isempty(current_candidates)
                xline(current_candidates,"LineWidth",3,"Color","black","LineStyle","--","Label","Candidate accuracy "+sprintf('%.2f',current_candidates))
            end
            close(f);
        end


    end

    function [mon_bef_log,mon_after_log] = check_for_monotonically_decreasing_and_increasing_surrounding_d(curve,candidates,options)
        %this function is trying to create a more valid metric for finding
        %support around candidates
        %instead of just checking the window for SOME points below some
        %threshold we check if the points are decreasing/increasing in the
        %specicified window
        %this way we don't rely on an arbitrary measurement
        smoothed_curve = movmean(curve,options.smoothing_window_for_mono_inc_dec);
        %it should be important to note that this function should detect
        %whether it increases/decreases around the candidate
        %The direction the increase/decrease happens is not guaranteed
        %thus it can go from increasing from the left of the candidate to
        %the increasing on the right or from decreasing on the left to
        %increasing on the right
        mon_bef_log = [];
        mon_after_log = [];
        for candidate_counter=1:length(candidates)
            before = diff(smoothed_curve(1:candidates(candidate_counter)));
            after = diff(smoothed_curve(candidates(candidate_counter):end));
            num_of_monotonically_dec_before = sum(before<=options.tol_for_mono_inc_dec);
            num_of_monotonically_dec_after = sum(after<=options.tol_for_mono_inc_dec);
            mon_bef_log = [mon_bef_log,num_of_monotonically_dec_before];
            mon_after_log = [mon_after_log,num_of_monotonically_dec_after];
        end
    end
    function get_poster_figs(options,blind_pass_table,estimated_accuracy,array_of_certainties)
        clc;
        close all;
        if options.only_above_60
            c1 = blind_pass_table{:,"accuracy"} > 70 & estimated_accuracy > 70;
            blind_pass_table(~c1,:) = [];
            estimated_accuracy(~c1) = [];
            array_of_certainties(~c1,:) = [];
        end
        for g=1:height(blind_pass_table)
            figure;
            bar(array_of_certainties(g,:),'grouped','blue','BarWidth',1);
            xline(blind_pass_table{g,"accuracy"},"LineWidth",5,"Color","black","Label","True accuracy "+sprintf('%.2f',blind_pass_table{g,"accuracy"}),"LabelHorizontalAlignment","right")
            xline(estimated_accuracy(g),"LineWidth",5,"Color","red","Label","Estimated accuracy "+sprintf('%.2f',estimated_accuracy(g)),"LabelHorizontalAlignment","left")
            xlabel("accuracy thresholds 1-100");
            ylabel("Certainty")
            save_it = input('save? (y/n/cancel) ', 's');
            if save_it=='y'
                format_poster_fig();
                exportgraphics(gcf, fullfile(options.dir_to_save_panel_figures_to, 'certainty_plots_row_'+string(g)+'.pdf'), 'ContentType', 'vector','BackgroundColor','none')
                close all;
            end
            if save_it=="cancel" || save_it == "c"
                break;
            end
            close all;
        end
    end


    function [valid_crossings,support_log,roughness_log] = check_candidates(candidates,curve,window,tol,smoothness_window,required,thresholds,distance_between_candidates)
        valid_crossings = [];
        support_log = [];
        roughness_log = [];
        for j = 1:numel(candidates) %go through every candidate and see if they meet certain criteria
            k = candidates(j); %current candidate

            before = curve(max(1,k-window+1):k); %get the window before the crossing
            after  = curve(k+1:min(numel(curve),k+window)); %get the window after the crossing

            before_support = sum(before > tol); % count how many instances in the before window are greater than the tolerance amount
            after_support  = sum(after < -tol); % count how many instances in the after window are less than the tolerance amount

            if before_support >= required && after_support >= required %ensure there's enough support on both sides of the crossing
                valid_crossings(end+1) = k; %add the candidate to the valid crossings
                support_log(end+1) = before_support + after_support; %record how much support the current crossing has

                local_curve = curve(max(1,k-smoothness_window):min(numel(curve),k+smoothness_window));

                roughness_log(end+1) = mean(diff(local_curve,2).^2);
            end
        end
        % Group only crossings that passed the support requirements.
        crossing_thresholds = thresholds(valid_crossings);
        crossing_thresholds = crossing_thresholds(:);

        group_id = cumsum([1;diff(crossing_thresholds) >= distance_between_candidates]);

        representative_indices = zeros(1,max(group_id));

        for p = 1:max(group_id)
            members = find(group_id == p);

            % Prefer the strongest support within this group.
            group_support = support_log(members);
            strongest = members(group_support == max(group_support));

            % Break support ties using local roughness.
            % An exact roughness tie selects the earlier crossing.
            [~,nearest] = min(roughness_log(strongest));
            representative_indices(p) = strongest(nearest);
        end

        % Keep all three arrays aligned.
        valid_crossings = valid_crossings(representative_indices);
        support_log = support_log(representative_indices);
        roughness_log = roughness_log(representative_indices);


        % First choose the crossings with the strongest support.
        best_indices = find(support_log == max(support_log));

        % If support is tied, prefer the smoothest local curve.
        if numel(best_indices) > 1
            tied_roughness = roughness_log(best_indices);
            min_roughness = min(tied_roughness);

            roughness_tolerance = 1e-10;
            best_indices = best_indices( ...
                abs(tied_roughness - min_roughness) <= roughness_tolerance);
        end
    end



    function [collapsed_candidates] = collapse_candidates_recursive(candidates,options)
        if length(candidates)<2
            collapsed_candidates = candidates;
            return;
        end
        %the goal here is to return a midpoint whenever you have candidates
        %within a certain distance of each other, it doesn't need to be at
        %a crossing point since they
        all_combos_of_candidates = nchoosek(candidates,2);

        distances_between_candidates = abs(all_combos_of_candidates(:,1)-all_combos_of_candidates(:,2));

        close_pairs = all_combos_of_candidates(distances_between_candidates <= options.min_distance, :);
        collapsible_candidates = unique(close_pairs(:));

        % Preserve candidates that appear in NO close pair.
        non_collapsed = candidates(~ismember(candidates, collapsible_candidates));
        non_collapsed = non_collapsed(:).'; % Ensure row vector

        collapsed_candidates = [];
        for collapse_counter=1:length(distances_between_candidates)
            if distances_between_candidates(collapse_counter) <= options.min_distance
                collapsed_candidates = [collapsed_candidates,round(median(all_combos_of_candidates(collapse_counter,:)))];
            end
        end

        collapsed_candidates = unique([collapsed_candidates,non_collapsed]);
        if isempty(collapsed_candidates)
            collapsed_candidates = candidates;
        end
        if numel(collapsed_candidates) <= 1 || isequal(sort(collapsed_candidates(:)), sort(candidates(:))) || all(distances_between_candidates > options.min_distance)
            return;
        end
        collapsed_candidates = collapse_candidates_recursive(collapsed_candidates, options);

    end

    function [estimated_accuracy] = fit_lines_to_candidates(curve,candidates,thresholds,options)
        estimated_accuracy = zeros(1,length(candidates));
        for j=1:length(candidates)
            k = candidates(j);
            w = options.window_for_polyfit;
            idx = max(1, k-w):min(numel(curve), k+w);

            p = polyfit(thresholds(idx), curve(idx), 1);
            slope = p(1);
            intercept = p(2);
            estimated_accuracy(j) = -intercept / slope;

            if estimated_accuracy(j) < 0 || estimated_accuracy(j) > 100
                estimated_accuracy(j) = 1;
            end
        end
    end

    function create_heatmaps_for_accuracy(blind_pass_table,estimated_accuracies,options)
        cell_arr_of_edges = options.edges_for_heatmap;
        for ed_co = 1:length(cell_arr_of_edges)
            curr_edges = cell_arr_of_edges{ed_co};

            % 1. Sample data
            trueLabels = repelem("",height(blind_pass_table),1);
            predLabels = repelem("",height(blind_pass_table),1);
            bounds = strcat(string(curr_edges(1:end-1)),"-",string(curr_edges(2:end)));

            for p=1:length(curr_edges)-1
                cond_for_true_labels = blind_pass_table.accuracy > curr_edges(p) & blind_pass_table.accuracy <= curr_edges(p+1);
                trueLabels(cond_for_true_labels) = bounds(p);
                cond_for_pred_labels = estimated_accuracies > curr_edges(p) & estimated_accuracies <= curr_edges(p+1);
                predLabels(cond_for_pred_labels) = bounds(p);
            end

            % --- MODIFIED FOR DEDICATED NaN CATEGORY ---
            % Instead of grouping them with "0-10", give them a clear, distinct string
            predLabels(isnan(estimated_accuracies)) = "NaN";
            trueLabels(isnan(blind_pass_table.accuracy)) = "NaN";

            % Append "NaN" as the final element in your ordered list
            all_categories = [bounds, "NaN"];

            % Convert strings to ordered categorical arrays
            trueLabels_cat = categorical(trueLabels, all_categories, 'Ordinal', true);
            predLabels_cat = categorical(predLabels, all_categories, 'Ordinal', true);
            % -------------------------------------------

            % 2. Calculate the numeric confusion matrix data using categorical inputs
            [C, groups] = confusionmat(trueLabels_cat, predLabels_cat);

            % 3. Feed the numerical data directly into a Heatmap Chart
            figure
            h = heatmap(groups, groups, (C ./ sum(C,2)) * 100);

            % 4. Tweak properties just like a traditional heatmap
            h.Title = 'Percentage of True Class Predicted To be Given Class';
            h.XLabel = 'Predicted Classes';
            h.YLabel = 'True Classes';
            h.Colormap = sky;

            figure
            h = heatmap(groups, groups, (C ./ sum(C,1)) * 100);

            h.Title = 'Percentage Of Predicted Class That Belong to Given Class ';
            h.XLabel = 'Predicted Classes';
            h.YLabel = 'True Classes';
            h.Colormap = sky;
        end
    end



    function [candidates] = find_candidates(y)
        zero_crossings = find(y(1:end-1) .* y(2:end) <= 0);

        if ~isempty(zero_crossings)
            % --- CASE A: Zero crossing exists ---
            % Linearly interpolate to find the exact fractional index if desired,
            % or just take the nearest integer index:
            candidates = zero_crossings;

        else
            % --- CASE B: Never crosses zero, find closest inflection point ---
            % fprintf('No zero crossing found. Searching for closest inflection point...\n');

            % Find inflection points where the second derivative changes sign
            d2y = diff(diff(y));
            inflection_pts = find(d2y(1:end-1) .* d2y(2:end) <= 0) + 1;

            if ~isempty(inflection_pts)
                % Find which inflection point is closest to the zero boundary
                % (i.e., the value of y is closest to 0)
                % [~, min_idx] = min(abs(y(inflection_pts)));
                candidates = inflection_pts;
                % fprintf('Closest inflection point found at index: %d (y = %.2f)\n', target_idx, y(target_idx));
            else
                % Ultimate fallback if the curve is a straight line with no inflection
                [~, candidates] = min(abs(y));
                % fprintf('No inflection points found. Returning point closest to zero at index: %d\n', target_idx);
            end
        end

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

%get rid of any tiny clusters since they're usually worthless
size_of_clusters = cell2mat(cellfun(@size,blind_pass_table.cluster_idx,'UniformOutput',false));
size_for_each_cluster = max(size_of_clusters,[],2);
blind_pass_table(size_for_each_cluster<100,:) = [];
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
array_of_certainties_unsmoothed = array_of_certainties;
array_of_certainties = smoothdata(array_of_certainties,2,"gaussian");
thresholds = table_of_nets.net_num;
num_clusters = size(array_of_certainties,1);

tol = options.tol;
window = options.window;
required = options.required;
smoothness_window = options.smoothness_window;
distance_between_candidates = options.distance_between_candidates;

estimated_accuracy = nan(num_clusters,1);
reliable_mask = false(num_clusters,1);
rejection_reason = strings(num_clusters,1);
cell_array_of_candidates = cell(num_clusters,1);

for r = 1:num_clusters
    curve = array_of_certainties(r,:); %get the current curve

    if any(~isfinite(curve)) %reject any curve that has infine values
        rejection_reason(r) = "Nonfinite predictions";
        continue
    end

    % lowest_point_in_the_curve = abs(curve); %we use this because sometimes a curve may be completely above/below 0, so we can't use true 0, we have to use the
    % downward = curve(1:end-1) >= 0 & curve(2:end) < 0; %candidates where the the curve goes from positive to negative
    % upward   = curve(1:end-1) < 0 & curve(2:end) >= 0; %candidates where the curve goes from negative to positive


    % candidates = find(downward | upward); %all candidates
    candidates = find_candidates(curve);

    candidates = collapse_candidates_recursive(candidates,options);


    cell_array_of_candidates{r} = candidates;

    if length(candidates) > 3 % reject anything with more than 3 crossings since they tend to be very unstable
        rejection_reason(r) = "unstable crossings";
        continue;
    end

    if length(candidates) >1 && (any(candidates >86) || any(candidates<5))
        candidates(candidates >86 | candidates<5) = [];
    end
    if isempty(candidates) %reject any rows that have no crossings
        rejection_reason(r) = "No candidates";
        continue
    end
    estimated_accuracy_for_curve = fit_lines_to_candidates(curve,candidates,thresholds,options);

    if length(estimated_accuracy_for_curve) >1
        estimated_accuracy_for_curve = fit_lines_to_candidates(curve, candidates, thresholds, options);
        if numel(estimated_accuracy_for_curve) > 1
            [mon_bef_log, mon_after_log] =check_for_monotonically_decreasing_and_increasing_surrounding_d(curve, candidates, options);

            % Assumes one scalar support score per candidate on each side.
            sums_of_support = mon_bef_log(:) + mon_after_log(:);

            indices_of_best = find(sums_of_support == max(sums_of_support));

            if numel(indices_of_best) ~= 1
                rejection_reason(r) = "not enough support to narrow down to single candidate";
                continue; % Continue the enclosing loop over curves.
            end

            estimated_accuracy_for_curve = estimated_accuracy_for_curve(indices_of_best);

        end

    end
    estimated_accuracy(r) = estimated_accuracy_for_curve;
    if estimated_accuracy(r) < 0 || estimated_accuracy(r) >100
        disp("something went wrong here");
    end
    reliable_mask(r) = true;
    rejection_reason(r) = "Accepted";
    fprintf("%i / %i\n",r,num_clusters)
end
% disp(groupcounts(table(rejection_reason),"rejection_reason"))

% filter_mask = reliable_mask & estimated_accuracy >= options.where_to_filter_by;

filter_mask = estimated_accuracy >= options.uncertainty_window(2);
rows_to_keep = blind_pass_table(filter_mask,:);

refinement_rows = estimated_accuracy >= options.uncertainty_window(1) & estimated_accuracy <= options.uncertainty_window(2);
rows_flagged_for_refinement = blind_pass_table(refinement_rows,:);
rows_to_discard = filter_mask |  refinement_rows;
if options.make_after_filt_acc_hist
    figure;
    histogram(rows_to_keep.accuracy,'BinEdges',0:1:100);
    title("Distributions of accuracy After Filter")
end
if options.get_statistics_of_faliures && ismember("accuracy",bp_var_names)
    get_statistics_of_faliures(blind_pass_table,options,filter_mask);
end

if options.make_confusion_matrix_heatmap && ismember("accuracy",bp_var_names)
    create_heatmaps_for_accuracy(blind_pass_table,estimated_accuracy,options)
end
if options.analyze_failure_cases
    analyze_faliure_cases(filter_mask,blind_pass_table,options,array_of_certainties,reliable_mask,estimated_accuracy,rejection_reason,cell_array_of_candidates);
end

if options.create_figures_for_choose_better_poster_panel
    get_poster_figs(options,blind_pass_table,estimated_accuracy,array_of_certainties)
end
end