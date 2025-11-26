function [] = scroll_to_complimentary_row_in_table(table_to_scroll,row_to_scroll_to)
if isempty(row_to_scroll_to)
    disp("No Matching Row")
    return;
end
% Assuming 'app.UITable' is the name of your Table UI component
removeStyle(table_to_scroll);

%scroll to the complementary row in the second table
scroll(table_to_scroll, 'row',row_to_scroll_to)



highlightStyle = uistyle('BackgroundColor', [0.9 0.9 0.9], 'FontWeight', 'bold','FontColor','black'); % Light gray, bold font

% Apply the style to the specified rows
addStyle(table_to_scroll, highlightStyle, 'row', row_to_scroll_to);
end