function [] = update_ui_table(table_to_update,table_to_update_with)        
variable_names = string(table_to_update_with.Properties.VariableNames);
table_to_update.ColumnName = variable_names;
table_to_update.Data = table_to_update_with;
end