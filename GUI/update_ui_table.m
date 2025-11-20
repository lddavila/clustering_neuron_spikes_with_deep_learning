function [] = update_ui_table(table_to_update,table_to_update_with,varargin)
if ~isempty(varargin)
    variable_names = [varargin{1}];
else    
    variable_names = string(table_to_update_with.Properties.VariableNames);
end
table_to_update.ColumnName = variable_names;
table_to_update.Data = table_to_update_with;
end