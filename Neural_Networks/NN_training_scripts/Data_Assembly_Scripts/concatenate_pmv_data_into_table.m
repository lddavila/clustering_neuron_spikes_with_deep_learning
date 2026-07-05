function [final_table] = concatenate_pmv_data_into_table(dir_to_pmv_data)
all_pmv_structs = struct2table(dir(fullfile(dir_to_pmv_data,"*.mat")));
all_pmv_structs.folder = string(all_pmv_structs.folder);
all_pmv_structs.name = string(all_pmv_structs.name);

final_table = [];
q = parallel.pool.DataQueue;
afterEach(q,@print_status_bar)
num_iterations = height(all_pmv_structs);
print_status_bar(num_iterations,"concatenate_pmv_data_into_table");
for i=1:height(all_pmv_structs)
    current_pmv_cell_array = load(fullfile(all_pmv_structs{i,"folder"},all_pmv_structs{i,"name"}));
    current_pmv_cell_array = current_pmv_cell_array.data_to_save;

    cum_count = cell(length(current_pmv_cell_array),1);
    cdf_count = cell(length(current_pmv_cell_array),1);
    pdf_count = cell(length(current_pmv_cell_array),1);
    density_count = cell(length(current_pmv_cell_array),1);
    percentage_count = cell(length(current_pmv_cell_array),1);
    prob_count = cell(length(current_pmv_cell_array),1);
    raw_count = cell(length(current_pmv_cell_array),1);
    tetrode_level_snr = nan(length(current_pmv_cell_array),1,1);
    %split_file_names = split(all_pmv_structs.name,"_");
    tetrode = repelem("",length(current_pmv_cell_array),1);
    z_score = nan(length(current_pmv_cell_array),1,1);
    percentile = nan(length(current_pmv_cell_array),1,1);
    recall  = cell(length(current_pmv_cell_array),1,1);
    f1  = cell(length(current_pmv_cell_array),1,1);
    precision  = cell(length(current_pmv_cell_array),1,1);
    for j=1:length(current_pmv_cell_array)
        current_pmv = current_pmv_cell_array{j};
        cum_count{j} = current_pmv.cdf_counts;
        cdf_count{j} = current_pmv.cdf_counts;
        pdf_count{j} = current_pmv.pdf_counts;
        density_count{j} = current_pmv.count_density_counts;
        percentage_count{j} = current_pmv.percentage_counts;
        prob_count{j} = current_pmv.prob_counts;
        raw_count{j} = current_pmv.raw_counts;
        tetrode_level_snr(j) = current_pmv.tetrode_level_snr;
        tetrode(j) = current_pmv.tetrode;
        z_score(j) = current_pmv.z_score;
        percentile(j) = current_pmv.percentile;
        precision{j} = current_pmv.tetrode_level_precision;
        f1{j} = current_pmv.tetrode_level_f1.';
        recall{j} = current_pmv.tetrode_level_recall;
    end
    mean_f1 = mean(cell2mat(f1),2,'omitnan');
    if any(mean_f1 < 0 | mean_f1 > 1)
        disp("something wrong");
    end
    table_of_pmv_data = table(z_score,tetrode,percentile,...
        tetrode_level_snr,raw_count,prob_count,...
        percentage_count,density_count,pdf_count,cdf_count,cum_count,...
        precision,f1,mean_f1,recall);
    
    final_table = [final_table;table_of_pmv_data];

    send(q,[]);
   
end


end