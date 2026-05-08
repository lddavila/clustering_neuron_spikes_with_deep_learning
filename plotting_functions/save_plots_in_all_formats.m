function [] = save_plots_in_all_formats(figure_to_save,file_savename)
% saveas(figure_to_save,file_savename+".svg")
saveas(figure_to_save,file_savename+".png")
saveas(figure_to_save,file_savename+".fig")
end