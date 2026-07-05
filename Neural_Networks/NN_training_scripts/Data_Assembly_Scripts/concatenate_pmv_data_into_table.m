function [table_of_pmv_data] = concatenate_pmv_data_into_table(dir_to_pmv_data)
all_pmv_structs = struct2table(dir(fullfile(dir_to_pmv_data,"*.mat")));
all_pmv_structs.folder = string(all_pmv_structs.folder);
all_pmv_structs.name = string(all_pmv_structs.name);

cum_count = cell(height(all_pmv_structs));
cdf_count = cell(height(all_pmv_structs));
pdf_count = cell(height(all_pmv_structs));
density_count = cell(height(all_pmv_structs));
percentage_count = cell(height(all_pmv_structs));
prob_count = cell(height(all_pmv_structs));
raw_count = cell(height(all_pmv_structs));
tetrode_level_snr = nan(height(all_pmv_structs),1);
split_file_names = split(all_pmv_structs.name,"_");
tetrode =split_file_names(:,1);
z_score = str2double(split_file_names(:,4));
percentile = str2double(split_file_names(:,end));
for i=1:height(all_pmv_structs)
    current_pmv = load(all_pmv_structs{i,"folder"},all_pmv_structs{i,"name"});
    current_pmv = current_pmv.data_to_save;
    cum_count{i} = current_pmv.cdf_counts;
    cdf_count{i} = current_pmv.cdf_counts;
    pdf_count{i} = current_pmv.pdf_counts;
    density_count{i} = current_pmv.count_density_counts;
    percentage_count{i} = current_pmv.percentage_counts;
    prob_count{i} = current_pmv.prob_counts;
    raw_count{i} = current_pmv.raw_counts;
    tetrode_level_snr(i) = current_pmv.tetrode_level_snr;

end
table_of_pmv_data = table(z_score,tetrode,percentile,tetrode_level_snr,raw_count,prob_count,percentage_count,density_count,pdf_count,cdf_count,cum_count);

end