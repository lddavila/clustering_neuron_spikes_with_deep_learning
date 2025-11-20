function fig = app_progress_bar(title_to_use)

fig = uifigure('Visible','on');

d = uiprogressdlg(fig, ...
    'Title', title_to_use, ...
    'Indeterminate', 'on');

drawnow
end