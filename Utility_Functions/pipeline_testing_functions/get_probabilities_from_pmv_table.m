function [table_of_probabilities] = get_probabilities_from_pmv_table(pmv_table,which_score_to_cdf,some_threshold_for_scores,make_plots)
% sliced_table = slice_table_for_parallel_processing(pmv_table,["percentile","z_score"]);
table_of_probabilities = [];
z_score = unique(pmv_table.z_score);
percentiles = unique(pmv_table.percentile);
all_combos = combinations(z_score,percentiles);
probabilities_to_use = nan(size(all_combos,1),length(which_score_to_cdf));
var_names = repelem("",length(which_score_to_cdf));
for j=1:length(which_score_to_cdf)
    for i=1:size(all_combos,1)
        c1 = all_combos{i,1} == pmv_table{:,"z_score"};
        c2 = all_combos{i,2} == pmv_table{:,"percentile"};
        local_data = pmv_table(c1 & c2,:);
        data_to_cdf = local_data.(which_score_to_cdf(j));
        if which_score_to_cdf(j)== "precision" || which_score_to_cdf(j)=="f1" || which_score_to_cdf(j)=="recall"
            if which_score_to_cdf(j)=="f1"
                data_to_cdf = cellfun(@transpose,data_to_cdf,'UniformOutput',false);
            end
            data_to_cdf = cell2mat(data_to_cdf);
        else
        end
        probabilities_to_use(i,j) = mean(data_to_cdf>some_threshold_for_scores);
        % send(q,[]);

    end
    var_names(j) = "prob_of_"+which_score_to_cdf(j)+"_to_be_above_"+string(some_threshold_for_scores);
end
table_of_probabilities = array2table([all_combos{:,1},all_combos{:,2},probabilities_to_use],'VariableNames',["Z Score", "Percentiles", var_names]);

if make_plots
    % grouped_data = slice_table_for_parallel_processing(table_of_probabilities,"Z Score");
    prob_names_in_table = string(table_of_probabilities.Properties.VariableNames);
    prob_vars =prob_names_in_table(contains(prob_names_in_table,"prob_of_"));
    for j=1:length(prob_vars)
        f = figure;
        grouped_data = slice_table_for_parallel_processing(table_of_probabilities,"Z Score");
        plot_colors = distinguishable_colors(length(grouped_data));
        for i=1:length(grouped_data)
            current_data = grouped_data{i};
            x_data = current_data{:,"Percentiles"};
            y_data = current_data{:,prob_vars(j)};
            plot(x_data,y_data,'Color',plot_colors(i,:),'LineWidth',2,"DisplayName","Z Score "+string(current_data{1,"Z Score"}));
            hold on;
        end
        xlabel("percentile")
        ylabel(strrep(prob_vars(j),"_","\_"))
        title(strrep(which_score_to_cdf(j),"_","\_"));
        legend;
    end
end


end
