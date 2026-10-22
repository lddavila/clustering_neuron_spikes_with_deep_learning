function format_poster_fig()
remove_tics()
% disp("///////////////////////")
set(gca, 'Color', 'none');
set(gca, 'FontSize', 20, 'FontName', 'Arial')
set(gcf, 'Renderer', 'painters');
end