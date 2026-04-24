function [] = run_tp_fp_tn_fn_score_calculator_with_hyp_params(varargin)
home_dir = cd("..");
cd("..");
addpath(genpath(pwd));
cd(home_dir);

config = spikesort_config();
if isempty(varargin)
    if contains(pwd,"scratch2")
        blind_pass_table = importdata(fullfile(config));
    else
        blind_pass_table = importdata(config.data_dir,"odd_recordings");
    end
else
    blind_pass_table = varargin{1};
end
sliced_bp_table = slice_table_for_parallel_processing(blind_pass_table,"recording_name");
all_possible_certainties = .95:-0.05:.50;
number_of_neural_nets_that_must_agree = 1:1:5;

dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"TP_FP_TN_FN_Results"));
statistics_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"statistics heatmaps"));
line_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"line plots"));
count_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"count heatmap"));
for i=1:length(sliced_bp_table)

    current_data = sliced_bp_table{i};

    current_recording = current_data{1,"recording_name"};
    save_name = fullfile(dir_to_save_results_to,current_recording+".mat");
    if ~isfile(save_name)
        [tp_array,tn_array,fp_array,fn_array] = get_simple_grouping_tp_fp_tn_fn_scores(current_data,config,all_possible_certainties,number_of_neural_nets_that_must_agree);
        comparison_statistics = struct();
        comparison_statistics.tp_array = tp_array;
        comparison_statistics.tn_array = tn_array;
        comparison_statistics.fp_array = fp_array;
        comparison_statistics.fn_array = fn_array;
        par_save(save_name,comparison_statistics)
    else
        comparison_statistics = importdata(save_name);
        tp_array = comparison_statistics.tp_array;
        tn_array = comparison_statistics.tn_array;
        fp_array = comparison_statistics.fp_array;
        fn_array = comparison_statistics.fn_array;
    end

    

    for j=1:size(tp_array,1)
        for k=1:size(tp_array,2)
            f = figure;
            nexttile();
            tp_flat = squeeze(tp_array(j,k,:));
            tn_flat = squeeze(tn_array(j,k,:));
            fp_flat = squeeze(fp_array(j,k,:));
            fn_flat = squeeze(fn_array(j,k,:));
            modified_tp = zeros(1,length(tp_flat));
            modified_tn = zeros(1,length(tp_flat));
            modified_fp = zeros(1,length(tp_flat));
            modified_fn = zeros(1,length(tp_flat));

            for q=1:length(modified_tp)
                if q ~=1
                    modified_tp(q) = sum(tp_flat(1:q));
                    modified_tn(q) = sum(tn_flat(1:q));
                    modified_fp(q) = sum(fp_flat(1:q));
                    modified_fn(q) = sum(fn_flat(1:q));
                else
                    modified_tp(q) = sum(tp_flat(q));
                    modified_tn(q) = sum(tn_flat(q));
                    modified_fp(q) = sum(fp_flat(q));
                    modified_fn(q) = sum(fn_flat(q));
                end
            end

            plot(modified_tp);
            hold on;
            plot(modified_tn);
            plot(modified_fp);
            plot(modified_fn);
            generic_title = "Certainty "+string(all_possible_certainties(k)) +" NN Agree "+ string(number_of_neural_nets_that_must_agree(j));
            title(generic_title);

            legend("TP","TN","FP","FN")
            save_plots_in_all_formats(f,fullfile(line_dir,generic_title+"_line_plots"));
            close(f)
            
            f = figure('Visible','off');
            xvalues = {'TP','TN','FP','FN'};
            yvalues = {'Frequency'};
            h =heatmap(xvalues,yvalues,[sum(tp_flat),sum(tn_flat),sum(fp_flat),sum(fn_flat)]);
            title(generic_title);
            h.CellLabelFormat = '%.f'; 
            save_plots_in_all_formats(f,fullfile(count_dir,generic_title+"_heat_maps"))
            close(f)

            f = figure();
            tp = sum(tp_flat);
            tn = sum(tn_flat);
            fp = sum(fp_flat);
            fn = sum(fn_flat);
            accuracy = (tp + tn) / (tp + tn + fp + fn);
            precision = tp / (tp + fp);
            recall = tp / (tp + fn);
            f1_score = 2 *( (precision * recall) / (precision + recall)) ;

            xvalues = {'accuracy','precision','recall','f1 score'};
            yvalues = {'score'};
            h =heatmap(xvalues,yvalues,[accuracy,precision,recall,f1_score]);
            h.CellLabelFormat = '%.6f'; 
            title(generic_title);
            save_plots_in_all_formats(f,fullfile(statistics_dir,generic_title+"_scores"))
            close(f);
        end
        
    end
end
end