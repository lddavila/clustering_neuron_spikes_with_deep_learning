function [blind_pass_table] = get_grades_for_nth_pass_of_clustering_ver_2(blind_pass_table,config,options)
arguments
    blind_pass_table table                 %required
    config struct               %required
    options.optional_alternate_grade_path string = "" % Optional named argument
end
% run_grading_script_on_blind_pass
if ~all(isfile(config.TEMPLATE_CLUSTER_FP))
    draw_elipse_templates(config);
end
%update paths on the blind pass table
% blind_pass_table = update_fpths(blind_pass_table,config);
sliced_blind_pass_table = slice_table_for_parallel_processing(blind_pass_table,[]);
debug = 0;

grading_error_dir = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.error_dir,"grading_errors"));


precomputed_dir = config.BLIND_PASS_DIR_PRECOMPUTED;
num_iterations = size(sliced_blind_pass_table,1);
grades_table = cell(size(blind_pass_table,1),1);

%for broken afriedman account close the parallel pool and reopen because
%for some reason it doesn't have the expected behavior
if contains(config.base_file_path,"afriedman")
    delete(gcp('nocreate'));  % 'nocreate' prevents error if no pool exists
    parpool('local_40', 40);
end

config =parallel.pool.Constant(config);

q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
print_status_bar(num_iterations,"get_grades_for_nth_pass_of_clustering_ver_2.m")
timestamps_array = importdata(config.Value.TIMESTAMP_FP);
parfor i=1:size(sliced_blind_pass_table,1)

    %disp("Starting grading")
    current_data = sliced_blind_pass_table{i};
    current_tetrode = current_data{1,"Tetrode"};



    tetrode_number = split(current_tetrode,"t");
    tetrode_number = str2double(tetrode_number(2));
    current_z_score = current_data{1,"Z Score"};
    % fprintf("Currently grading %s with z score %i\n",current_tetrode,current_z_score);
    if ~config.Value.use_new_spike_detection
        dir_to_save_grades_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass min z_score "+string(current_z_score)+" grades"+options.optional_alternate_grade_path));
    else
        dir_to_save_grades_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(precomputed_dir,"initial_pass min multiplier "+string(current_z_score)+" grades"+options.optional_alternate_grade_path));
    end
    grades_file_name =fullfile(dir_to_save_grades_to,current_tetrode+" Grades.mat");

    if isfile(grades_file_name)
        % disp(grades_file_name)
        % disp("has already been graded. To regrade delete the file and run again.")
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
        array_of_tetrodes = config.Value.ART_TETR_ARRAY;

        channels_of_curr_tetr = array_of_tetrodes(tetrode_number,:);
        ts_and_r_vals_fp = current_data{1,"fp_to_timestamps_rtvals"};

        aligned_fp = current_data{1,"fp_to_aligned"};

        try
            ts_r_tvals_cc_struct = load(ts_and_r_vals_fp ,"timestamps","r_tvals","cleaned_clusters");
            % timestamps = ts_r_tvals_cc_struct.timestamps;
            r_tvals = ts_r_tvals_cc_struct.r_tvals;
            cleaned_clusters = ts_r_tvals_cc_struct.cleaned_clusters;
        catch ME
            disp(ME.getReport);
            disp("failed to load");
            disp(ts_and_r_vals_fp);
            send(q,[]);
            continue;
        end

        base_spike_windows_fp =current_data{1,"fp_to_sorted_spike_windows_after_purges"};
        base_spike_windows_struct = load(base_spike_windows_fp,"data_to_save");
        base_spike_windows = base_spike_windows_struct.data_to_save;

        timestamps = timestamps_array(base_spike_windows(:,4));
       

        try
            aligned_struct = load(aligned_fp,"data_to_save");
            aligned = aligned_struct.data_to_save;
        catch ME
            disp(ME.getReport);
            disp("failed to load");
            disp(aligned_fp);
            send(q,[]);
            continue;
        end

        %compute_gradings_ver_4(aligned, timestamps, tvals, clusters, config,debug)


        dir_of_template_shape_pngs = config.Value.TEMPLATE_CLUSTER_FP;

        try
            grades = compute_gradings_ver_4(aligned, timestamps, r_tvals, cleaned_clusters, config.Value.spikesort,debug,channels_of_curr_tetr,dir_of_template_shape_pngs,config.Value);
        catch ME
            %if grading fails for ANY reason we want to log the data set
            %that causes it and get the error for later review
            report = ME.getReport;
            meta_data_text = sprintf("Grading threw error when i = %i\n tetrode: %s \n Multiplier or Z score: %i\n",i,current_data{1,"Tetrode"},current_data{1,"Z Score"});
            f_id = fopen(fullfile(grading_error_dir,sprintf("tetrode: %s Multiplier or Z score: %i",current_data{1,"Tetrode"},current_data{1,"Z Score"})+".txt"),"w");
            if f_id == -1
                error('File could not be opened.');
            end
            fprintf(f_id,meta_data_text);
            fprintf(f_id,report);
            fclose(f_id);
            continue;
        end
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
    variables_from_original_data = setdiff(string(current_data.Properties.VariableNames),"grades");
    for k=1:size(variables_from_original_data,2)
        grades_and_grades_fp_table.(variables_from_original_data(k)) = repelem(current_data{1, variables_from_original_data(k)},size(grades_and_grades_fp_table,1),1);
    end
    grades_table{i} = grades_and_grades_fp_table;
    %disp(grades_and_grades_fp_table{:,"grades"});
    % disp("################################################")
    send(q,[])

end

current_data = sliced_blind_pass_table{1};
all_other_variables = setdiff(string(current_data.Properties.VariableNames),["Z Score","Tetrode","Cluster","grades"]);
blind_pass_table = vertcat(grades_table{:});
blind_pass_table = blind_pass_table(:,["Z Score","Tetrode","Cluster","grades",all_other_variables]);


end