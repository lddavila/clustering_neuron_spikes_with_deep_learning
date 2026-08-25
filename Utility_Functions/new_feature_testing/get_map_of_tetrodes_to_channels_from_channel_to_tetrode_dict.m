function [mapping] = get_map_of_tetrodes_to_channels_from_channel_to_tetrode_dict(dir_with_dicts)
all_dicts = struct2table(dir(fullfile(dir_with_dicts,"*channel_to_tetrode_dictionary.mat")));
all_dicts.name = string(all_dicts.name);
all_dicts.folder = string(all_dicts.folder);
split_names = split(all_dicts.name," ");
all_dicts.tetrode_num = split_names(:,1);
all_dicts = sortrows(all_dicts,"tetrode_num");
mapping = cell(height(all_dicts),2);
for i=1:height(all_dicts)
    curr_dict = importdata(fullfile(all_dicts{i,"folder"},all_dicts{i,"name"}));
    curr_dict = curr_dict.channel_to_tetrode_dictionary;
    mapping{i,2} = {str2double(strrep(string(keys(curr_dict)),"c",""))};
    mapping{i,1} = all_dicts{i,"tetrode_num"};

end
mapping = cell2table(mapping,'VariableNames',["Tetrode","channels"]);
end