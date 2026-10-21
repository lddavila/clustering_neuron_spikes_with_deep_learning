close all;clc;
[config,local_figure_dir] = set_up_figure_creation("name_of_calling_file","choose_better_panel_figures");
dir_of_poster_data = fullfile(config.data_dir,"data_for_poster_figs");

%get a blind pass table
blind_pass_table = load(fullfile(dir_of_poster_data,"blind_pass_table_2_ch.mat"));
blind_pass_table = blind_pass_table.data_to_save;

%% get the nets which we'll use to build our curves 7 get the certainties
dir_with_nets = fullfile(config.base_file_path,"Neural_Networks","prob_dist_nets_temp_scaling_num_channels_var");
table_of_nets = struct2table(dir(fullfile(dir_with_nets,"*.mat")));
table_of_nets.name = string(table_of_nets.name);
table_of_nets.folder = string(table_of_nets.folder);
net_names = split(table_of_nets.name,"_");
table_of_nets.net_num = str2double(net_names(:,3));
table_of_nets = sortrows(table_of_nets,"net_num","ascend");
array_of_certainties = zeros(height(blind_pass_table),height(table_of_nets));

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

%%
clc;
close all;
[~,predicted_accuracies] = min(abs(array_of_certainties),[],2);
for i=1:height(blind_pass_table)
    f = figure;
    bar(array_of_certainties(i,:),'grouped','blue','BarWidth',1);
    xline(blind_pass_table{i,"accuracy"},"LineWidth",5,"Color","green","Label","True accuracy "+sprintf('%.2f',blind_pass_table{i,"accuracy"}))
    xline(predicted_accuracies(i),"LineWidth",5,"Color","red","Label","Estimated accuracy "+sprintf('%.2f',blind_pass_table{i,"accuracy"}))
    xlabel("accuracy thresholds 1-100");
    ylabel("Certainty (probability of being above - probability of being below)")
    save_it = input('y/n ', 's');
    

    if save_it=='y'
        format_poster_fig();
        exportgraphics(gcf, fullfile(local_figure_dir, 'certainty_plots_row_'+string(i)+'.pdf'), 'ContentType', 'vector','BackgroundColor','none')
        close all;
    end
end

%%
odd_recordings =load(fullfile(dir_of_poster_data,"odd_recordings.mat"));
odd_recordings = odd_recordings.odd_recordings;
%%
odd_recordings_with_filters = odd_recordings(odd_recordings{:,"accuracy"}<91,:);

%%
get_certainty_statistics_and_figs("C:\Users\ldd77\clustering_neuron_spikes_with_deep_learning\Default_Results_Dir\probability_distr_nets_equalized_difficulty_grades_3_with_temp_scaling",config,odd_recordings_with_filters,0,0)