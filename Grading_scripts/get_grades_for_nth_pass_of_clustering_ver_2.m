function [blind_pass_table] = get_grades_for_nth_pass_of_clustering_ver_2(blind_pass_table,config)

% run_grading_script_on_blind_pass
draw_elipse_templates(config);
sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,[]);
debug = 0;

precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;
num_iterations = size(sliced_blind_pass_table,1);
grades_table = cell(size(blind_pass_table,1),1);

config =parallel.pool.Constant(config);

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"get_grades_for_nth_pass_of_clustering_ver_2.m")
for i=1:size(sliced_blind_pass_table,1)
    current_data = sliced_blind_pass_table{i};
    current_tetrode = current_data{1,"Tetrode"};


    tetrode_number = split(current_tetrode,"t");
    tetrode_number = str2double(tetrode_number(2));
    current_z_score = current_data{1,"Z Score"};
    dir_to_save_grades_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass min z_score "+string(current_z_score)+" grades"));
    grades_file_name =fullfile(dir_to_save_grades_to,current_tetrode+" Grades.mat");

    if isfile(grades_file_name)
        disp(grades_file_name)
        disp("has already been graded. To regrade delete the file and run again.")
        grades_struct = load(grades_file_name);
        grades_struct = grades_struct.data_to_save;
        grades_struct = struct2table(grades_struct);
        grades = cell(size(grades_struct,1),size(grades_struct,2));
        for row_counter = 1:size(grades_struct,1)
            for col_counter = 1:size(grades_struct,2)
                grades{row_counter,col_counter} = grades_struct{row_counter,col_counter}{1};
            end
        end
    else
        array_of_tetrodes = build_artificial_tetrode();

        channels_of_curr_tetr = array_of_tetrodes(tetrode_number,:);
        ts_and_r_vals_fp = current_data{1,"fp_to_timestamps_rtvals"};

        aligned_fp = current_data{1,"fp_to_aligned"};

        try
            ts_r_tvals_cc_struct = importdata(ts_and_r_vals_fp ,"timestamps","r_tvals","cleaned_clusters");
            timestamps = ts_r_tvals_cc_struct.timestamps;
            r_tvals = ts_r_tvals_cc_struct.r_tvals;
            cleaned_clusters = ts_r_tvals_cc_struct.cleaned_clusters;
        catch
            disp("failed to load");
            disp(ts_and_r_vals_fp);
            send(q,[]);
            continue;
        end
        try
            aligned_struct = importdata(aligned_fp,"aligned");
            aligned = aligned_struct.aligned;
        catch
            disp("failed to load");
            disp(aligned_fp);
            send(q,[]);
            continue;
        end

        %compute_gradings_ver_4(aligned, timestamps, tvals, clusters, config,debug)
        if config.Value.ON_HPC
            dir_of_template_shape_pngs = config.Value.TEMPLATE_CLUSTER_FP_ON_HPC;
        else
            dir_of_template_shape_pngs = config.Value.TEMPLATE_CLUSTER_FP;
        end

        grades = compute_gradings_ver_4(aligned, timestamps, r_tvals, cleaned_clusters, config.Value.spikesort,debug,channels_of_curr_tetr,dir_of_template_shape_pngs,config.Value);
        grade_struct = struct();

        for j=1:size(grades,2)
            grade_struct.("Grade_"+string(j)) = grades(:,j);
        end
        par_save(grades_file_name,grade_struct);
    end





    grades_and_grades_fp_table = table(nan(size(grades,1),1),cell(size(grades,1),1),repelem("",size(grades,1),1),'VariableNames',["Cluster","grades","fp_to_grades"]);
    for k=1:size(grades_and_grades_fp_table,1)
        grades_and_grades_fp_table{k,"Cluster"} = k;
        grades_and_grades_fp_table{k,"grades"} = {grades(k,:)};
        grades_and_grades_fp_table{k,"fp_to_grades"} = fullfile(dir_to_save_grades_to,current_tetrode+" Grades.mat");
    end
    variables_from_original_data = string(current_data.Properties.VariableNames);
    for k=1:size(variables_from_original_data,2)
        grades_and_grades_fp_table.(variables_from_original_data(k)) = repelem(current_data{1, variables_from_original_data(k)},size(grades_and_grades_fp_table,1),1);
    end
    grades_table{i} = grades_and_grades_fp_table;
    %disp(grades_and_grades_fp_table{:,"grades"});
    send(q,[])

end
blind_pass_table = [];
parfor i=1:size(grades_table,1)
    current_data = grades_table{i};
    if isempty(current_data)
        continue;
    end
    all_other_variables = setdiff(string(current_data.Properties.VariableNames),["Z Score","Tetrode","Cluster","grades"]);
    blind_pass_table = [blind_pass_table;current_data(:,["Z Score","Tetrode","Cluster","grades",all_other_variables])];
end


end