function [] =analyze_accuracy_trends(table_of_accuracy,number_of_tetrodes_per_plot)
list_of_unique_tetrodes = unique(table_of_accuracy{:,"Tetrode"});
how_many_groups = ceil(length(list_of_unique_tetrodes)/number_of_tetrodes_per_plot);
tetrode_counter = 1;
for i=1:how_many_groups
    figure;
    tiledlayout(number_of_tetrodes_per_plot,1);
    %legend_strings = repelem("",1,number_of_tetrodes_per_plot);
    for j=1:number_of_tetrodes_per_plot
        if tetrode_counter > length(list_of_unique_tetrodes)
            continue;
        end
        nexttile();
        all_examples_for_current_tetrode = table_of_accuracy(table_of_accuracy{:,"Tetrode"}==list_of_unique_tetrodes(tetrode_counter),:);
        all_examples_for_current_tetrode = sortrows(all_examples_for_current_tetrode,"Z Score","ascend");
        plot(all_examples_for_current_tetrode{:,"Z Score"},all_examples_for_current_tetrode{:,"accuracy"});
        if j==number_of_tetrodes_per_plot
            xlabel("Z Score");
        end
        ylabel("accuracy")
        %title(list_of_unique_tetrodes(tetrode_counter));
        %legend_strings(j) = list_of_unique_tetrodes(tetrode_counter);  
        legend(list_of_unique_tetrodes(tetrode_counter));
        tetrode_counter = tetrode_counter +1;
        ylim([0,100])
    end
end
end