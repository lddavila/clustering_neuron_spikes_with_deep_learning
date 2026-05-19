function [table_of_percentiles] = get_all_accuracy_tables_from_testing(dir_with_tables)
% dir_with_tables = "E:\prc_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
% dir_with_tables = "E:\prc_2_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
table_of_percent_tables = struct2table(dir(fullfile(dir_with_tables,"*_bp_table*")));
table_of_percent_tables.folder = string(table_of_percent_tables.folder);
table_of_percent_tables.name = string(table_of_percent_tables.name);
table_of_percentiles = [];


parfor i=1:height(table_of_percent_tables)
    try
        current_name = table_of_percent_tables{i,"name"};
        the_local_table = importdata(fullfile(table_of_percent_tables{i,"folder"},current_name));
        prctiles_used = the_local_table.prctile_used;

        the_local_table = the_local_table.blind_pass_table;
        the_local_table.prctiles_used = repmat(prctiles_used,size(the_local_table,1),1);
        table_of_percentiles = [table_of_percentiles;the_local_table];
    catch
        disp("caught");
    end
    fprintf("Finished %i/%i\n",i,height(table_of_percent_tables))
end

end