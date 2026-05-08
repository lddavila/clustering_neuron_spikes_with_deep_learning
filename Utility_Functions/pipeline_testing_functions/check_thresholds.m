dir_with_tables = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
dir_with_tables = "E:\test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";
dir_with_tables = "E:\prc_test_ic_3_10_600Neuron300SecondRecordingWithLevel10Noise\DEBUG\ACCURACY";

all_tables = struct2table(dir(fullfile(dir_with_tables,"*t2*.mat")));
% all_tables = struct2table(dir(fullfile(dir_with_tables,"*_mult_4*.mat")));
all_tables.name = string(all_tables.name);
all_tables.folder = string(all_tables.folder);
table_to_fill = [];
accuracy_above_80_count = 0;
for i=1:height(all_tables)
    try
        current_name = all_tables{i,"name"};
        split_name = split(current_name,"_");
        the_local_table = importdata(fullfile(all_tables{i,"folder"},current_name));
        prctiles_used = the_local_table.prctile_used;
        if all(prctiles_used==[20 15 10 5])
            disp("hello")
        end
        the_local_table = the_local_table.blind_pass_table;
        the_local_table.prctiles_used = repmat(prctiles_used,size(the_local_table,1),1);
        table_to_fill = [table_to_fill;the_local_table];
        if any(the_local_table{:,"accuracy"}>80)
            accuracy_above_80_count = accuracy_above_80_count + 1;
        end
    catch
    end
    fprintf("Finished %i/%i\n",i,height(all_tables))
end

[~, uidx] = unique(table_to_fill.accuracy, 'stable');
T_unique = table_to_fill(uidx, :);
disp(T_unique(:,["Multiplier","Tetrode","cluster","Max_Overlap_Unit","accuracy","Max_Overlap_perc_With_Unit","timestamps","prctiles_used"]));

