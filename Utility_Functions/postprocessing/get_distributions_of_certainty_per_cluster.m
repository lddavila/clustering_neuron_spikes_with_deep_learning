function [] = get_distributions_of_certainty_per_cluster(blind_pass_table,config,varargin)

%first get all available nets
table_of_dists_nets = struct2table(dir(fullfile(config.dir_of_prob_dist_nets,"*.mat")));

%extract all the grades for the blind pass table
list_of_features_to_add = ["grades 2"];
grades_data = cell2mat(assemble_data_for_neural_net(list_of_features_to_add,blind_pass_table,config));

split_file_names = split(string(table_of_dists_nets{:,"name"}),"_");
thresholds = str2double(split_file_names(:,3));

table_of_dists_nets.accuracy_level = thresholds;

table_of_dists_nets = sortrows(table_of_dists_nets,"accuracy_level");

all_above_probabilities = cell(1,height(table_of_dists_nets));
all_below_probabilities = cell(1,height(table_of_dists_nets));
above_all_certainty_scores = cell(1,height(table_of_dists_nets));
below_all_certainty_scores = cell(1,height(table_of_dists_nets));
brier_score_weights = nan(height(table_of_dists_nets),1);

for i=1:height(table_of_dists_nets)
    
    net_struct = importdata(fullfile(table_of_dists_nets{i,"folder"}{1},table_of_dists_nets{i,"name"}{1}));
    if isfield(net_struct,"brier_score")
        brier_score_weights(i) = net_struct.brier_score;
    end
    net = net_struct.net;

    %rescale the grades data by getting the column min and max
    input_max = net_struct.InputMax;
    input_min = net_struct.InputMin;
    scaled_data = rescale(grades_data,-1,1,"InputMax",input_max,"InputMin",input_min);

    %use the net to get above below probabilities for the current threshold
    all_above_below_probabilities = predict(net,scaled_data);
    all_above_probabilities{i} = all_above_below_probabilities(:,2);
    all_below_probabilities{i} = all_above_below_probabilities(:,1);

    %get the certainty of decision
    above_all_certainty_scores{i} = all_above_probabilities{i} - all_below_probabilities{i};
    below_all_certainty_scores{i} =  all_below_probabilities{i} - all_above_probabilities{i};
    disp(i);
end

per_cluster_above_certainty = cell2mat(above_all_certainty_scores);
per_cluster_below_certainty = cell2mat(below_all_certainty_scores);
% all_above_probabilities = cell2mat(all_above_probabilities);
% all_above_probabilities = isotonic_regression_decreasing(all_above_probabilities);
all_below_probabilities = cell2mat(all_below_probabilities);
x = table_of_dists_nets.accuracy_level;


%get the monotonically decreasing probabilities
adjusted_below_probabilities = nan(size(all_below_probabilities));
adjusted_above_probabilities = nan(size(all_below_probabilities));
adjusted_below_certainty = nan(size(all_below_probabilities));

if all(isnan(brier_score_weights))
    weights = ones(length(x),1);
else
    weights = brier_score_weights;
end
for i=1:size(all_below_probabilities,1)
    adjusted_below_probabilities(i,:) = lsqisotonic(x,all_below_probabilities(i,:),weights);
    
    % adjusted_above_certainty(i,:) = lsqisotonic(x,per_cluster_above_certainty(i,:),weights);
    % adjusted_below_certainty(i,:) = lsqisotonic(x,per_cluster_below_certainty(i,:),weights);
    % fprintf("%i/%i\n",i,size(all_below_probabilities,1));
end
adjusted_above_probabilities = 1 - adjusted_below_probabilities;

% Calculate the 'Density' (how much probability drops at each threshold)
% We negate it because probabilities decrease as thresholds increase




certainty_strength = adjusted_above_probabilities - adjusted_below_probabilities;

above_certainty = max(certainty_strength, 0);
below_certainty = max(-certainty_strength, 0);
% adjusted_above_certainty = per_cluster_above_certainty;
if ~isempty(varargin) && varargin{1} && any(ismember(string(blind_pass_table.Properties.VariableNames),"accuracy"))
    for i=1:height(blind_pass_table)
        figure;
        plot(above_certainty(i,:));
        hold on;
        plot(below_certainty(i,:));
        accuracy_density = -diff([1, adjusted_above_probabilities(i,:)]); 
        plot(x, accuracy_density);
        p_a = adjusted_above_probabilities(i, :);
        p_b = adjusted_below_probabilities(i, :);
        entropy_curve = -(p_a .* log2(p_a) + p_b .* log2(p_b));
        plot(entropy_curve)
        xline(blind_pass_table{i,"accuracy"},'LineWidth',3,'Color','k','Label',"true_accuracy:"+string(blind_pass_table{i,"accuracy"}),"LineStyle","--");
        xlabel("accuracy")
        legend("Above certainty","Below Certainty","Probability Density of Cluster Accuracy","entropy curve","true accuracy")
        close all;
    end
end

end