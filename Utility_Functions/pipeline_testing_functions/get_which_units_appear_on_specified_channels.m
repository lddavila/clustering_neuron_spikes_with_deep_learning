function [table_with_all_current_channels] = get_which_units_appear_on_specified_channels(channels_to_check_for,dir_with_unit_detection_tables,varargin)
if isempty(varargin)
    table_of_all_unit_detection = struct2table(dir(fullfile(dir_with_unit_detection_tables,"*.mat")));
    table_of_all_unit_detection.name = string(table_of_all_unit_detection.name);
    table_of_all_unit_detection.folder = string(table_of_all_unit_detection.folder);
    table_with_all_current_channels = [];
    parfor i=1:height(table_of_all_unit_detection)
        current_table = importdata(fullfile(table_of_all_unit_detection{i,"folder"},table_of_all_unit_detection{i,"name"}));
        only_rows_with_desired_channels = any(ismember(current_table{:,"all_channels"},channels_to_check_for),2);
        table_with_all_current_channels = [table_with_all_current_channels;current_table(only_rows_with_desired_channels,:)];
    end
else
    table_with_all_current_channels = varargin{1};
end

%filter the rows down to only the rows where the unit is highly visible 
table_with_all_current_channels(table_with_all_current_channels{:,"detection_ratio"} < 80,:) = [];

end