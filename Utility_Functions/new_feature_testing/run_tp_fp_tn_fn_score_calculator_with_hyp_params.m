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
if isempty(varargin) ||length(varargin)==1
    dir_to_save_results_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.parent_save_dir,"TP_FP_TN_FN_Results"));
else
    dir_to_save_results_to = varargin{2};
end
statistics_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"statistics heatmaps"));
line_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"line plots"));
count_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"count heatmap"));
for i=1:length(sliced_bp_table)

    current_data = sliced_bp_table{i};

    current_recording = current_data{1,"recording_name"};
    save_name = fullfile(dir_to_save_results_to,current_recording+".mat");
    if length(varargin)<3
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
    else
        comparison_statistics = varargin{3};
        tp_array = comparison_statistics.tp_array;
        tn_array = comparison_statistics.tn_array;
        fp_array = comparison_statistics.fp_array;
        fn_array = comparison_statistics.fn_array;
    end



    recall_matrix = zeros(size(tp_array,1),size(tp_array,2));
    precision_matrix = zeros(size(tp_array,1),size(tp_array,2));
    accuracy_matrix = zeros(size(tp_array,1),size(tp_array,2));
    f1_matrix = zeros(size(tp_array,1),size(tp_array,2));
    matrix_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(dir_to_save_results_to,"matrix_dir"));
    matrix_object = struct();
    matrix_object_fn = fullfile(matrix_dir,"matrix_object"+current_data{1,"recording_name"}+".mat");
    if ~isfile(matrix_object_fn)
        for j=1:size(tp_array,1)
            for k=1:size(tp_array,2)
                % f = figure('Visible',"off");
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

                % plot(modified_tp);
                % hold on;
                % plot(modified_tn);
                % plot(modified_fp);
                % plot(modified_fn);
                % generic_title = "Certainty "+string(all_possible_certainties(k)) +" NN Agree "+ string(number_of_neural_nets_that_must_agree(j));
                % title(generic_title);
                %
                % legend("TP","TN","FP","FN")
                % save_plots_in_all_formats(f,fullfile(line_dir,generic_title+"_line_plots"));
                % close(f)

                % f = figure('Visible','off');
                % xvalues = {'TP','TN','FP','FN'};
                % yvalues = {'Frequency'};
                % h =heatmap(xvalues,yvalues,[sum(tp_flat),sum(tn_flat),sum(fp_flat),sum(fn_flat)]);
                % title(generic_title);
                % h.CellLabelFormat = '%.f';
                % save_plots_in_all_formats(f,fullfile(count_dir,generic_title+"_heat_maps"))
                % close(f)

                % f = figure('Visible','off');
                tp = sum(tp_flat);
                tn = sum(tn_flat);
                fp = sum(fp_flat);
                fn = sum(fn_flat);
                accuracy_matrix(j,k) = (tp + tn) / (tp + tn + fp + fn);
                precision_matrix(j,k) = tp / (tp + fp);
                recall_matrix(j,k) = tp / (tp + fn);
                f1_matrix(j,k) = 2 *( (precision_matrix(j,k) * recall_matrix(j,k)) / (precision_matrix(j,k) + recall_matrix(j,k))) ;
                fprintf("i: %i/%i j:%i/%i k:%i/%i \n",i,length(sliced_bp_table),j,size(tp_array,1),k,size(tp_array,2));
            end

        end
        matrix_object.recall = recall_matrix;
        matrix_object.accuracy = accuracy_matrix;
        matrix_object.precision = precision_matrix;
        matrix_object.f1 = f1_matrix;


        par_save(matrix_object_fn,matrix_object)
    else
        matrix_object = importdata(matrix_object_fn);
        recall_matrix = matrix_object.recall;
        accuracy_matrix = matrix_object.accuracy;
        precision_matrix = matrix_object.precision;
        f1_matrix = matrix_object.f1;
    end
    yvalues = {'1 NN','2 NNs','3 NNs','4 NNs', '5 NNs'};
    xvalues = {'0.95','0.90','0.85','0.80','0.75','0.70','0.65','0.60','0.55','0.50'};

    f = figure('units','normalized','outerposition',[0 0 1 1]);
    h =heatmap(xvalues,yvalues,recall_matrix);
    h.CellLabelFormat = '%.6f';
    title("Recall");
    ylabel("# of NNs that need to agree");
    xlabel("Certainty outcome");
    save_plots_in_all_formats(f,fullfile(statistics_dir,"recall"))
    close(f);

    f = figure('units','normalized','outerposition',[0 0 1 1]);
    h =heatmap(xvalues,yvalues,accuracy_matrix);
    h.CellLabelFormat = '%.6f';
    title("Accuracy");
    ylabel("# of NNs that need to agree");
    xlabel("Certainty outcome");
    save_plots_in_all_formats(f,fullfile(statistics_dir,"accuracy"))
    close(f);

    f = figure('units','normalized','outerposition',[0 0 1 1]);
    h =heatmap(xvalues,yvalues,precision_matrix);
    h.CellLabelFormat = '%.6f';
    title("Precision");
    ylabel("# of NNs that need to agree");
    xlabel("Certainty outcome");
    save_plots_in_all_formats(f,fullfile(statistics_dir,"precision"))
    close(f);

    f = figure('units','normalized','outerposition',[0 0 1 1]);
    tiledlayout("flow")

    x_values = [0.95,0.90,0.85,0.80,0.75,0.70,0.65,0.60,0.55,0.50];

    nexttile();
    plot_f1_recall_and_precision_as_line_plots(f1_matrix*100,[0.95,0.90,0.85,0.80,0.75,0.70,0.65,0.60,0.55,0.50],["1 NN","2 NNs","3 NNs","4 NNs", "5 NNs"])
    remove_tics("remove_x",false);
    xlabel("Probability of Merge Classification")
    ylabel("F1 Score")
    format_poster_fig();

    nexttile();
    plot_f1_recall_and_precision_as_line_plots(precision_matrix*100,[0.95,0.90,0.85,0.80,0.75,0.70,0.65,0.60,0.55,0.50],["1 NN","2 NNs","3 NNs","4 NNs", "5 NNs"])
    xlabel("Probability of Merge Classification")
    ylabel("Precision Score")
    remove_tics("remove_x",false);
    format_poster_fig();

    nexttile();
    plot_f1_recall_and_precision_as_line_plots(recall_matrix*100,[0.95,0.90,0.85,0.80,0.75,0.70,0.65,0.60,0.55,0.50],["1 NN","2 NNs","3 NNs","4 NNs", "5 NNs"])
    xlabel("Probability of Merge Classification")
    ylabel("Recall Score")
    remove_tics("remove_x",false);
    legend;

    set(gcf, 'Renderer', 'painters');
    format_poster_fig();
    exportgraphics(gcf, fullfile(dir_to_save_results_to, 'Line_plots.pdf'), 'ContentType', 'vector','Resolution', 300,'BackgroundColor','none')



end
end