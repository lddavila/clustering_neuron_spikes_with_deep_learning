function summary_file = save_pipeline_summary(summary, result_files, ...
        input_file, matrix_file, model_file, output_folder, total_seconds)
%SAVE_PIPELINE_SUMMARY Save the cutoff table and a compact comparison figure.

summary = sortrows(summary, "accuracy_cutoff");
summary_file = fullfile(output_folder, "accuracy_cutoff_summary.mat");
csv_file = fullfile(output_folder, "accuracy_cutoff_summary.csv");
figure_file = fullfile(output_folder, "accuracy_cutoff_summary.png");

writetable(summary, csv_file);

can_plot_ground_truth = any(isfinite(summary.accuracy_cutoff)) && ...
    any(isfinite(summary.fully_pure_group_percent));

if can_plot_ground_truth
    figure_handle = figure("Color", "white", "Visible", "off", ...
        "Position", [80 100 1400 720]);
    tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    nexttile
    plot(summary.accuracy_cutoff, summary.groups_per_unit_ratio, ...
        "o-", "LineWidth", 1.8, "MarkerSize", 6);
    yline(1, "--", "ideal ratio = 1", "LineWidth", 1.1);
    xlabel("Minimum cluster accuracy (%)");
    ylabel("Final groups / retained units");
    title("Fragmentation");
    grid on

    nexttile
    plot(summary.accuracy_cutoff, summary.fully_pure_group_percent, ...
        "o-", "LineWidth", 1.8, "MarkerSize", 6);
    xlabel("Minimum cluster accuracy (%)");
    ylabel("Fully pure groups (%)");
    title("Completely pure groups");
    ylim([0 100]);
    grid on

    nexttile
    plot(summary.accuracy_cutoff, summary.clusters_in_pure_percent, ...
        "o-", "LineWidth", 1.8, "MarkerSize", 6);
    xlabel("Minimum cluster accuracy (%)");
    ylabel("Clusters in pure groups (%)");
    title("Cluster coverage");
    ylim([0 100]);
    grid on

    nexttile
    plot(summary.accuracy_cutoff, summary.unit_retention_percent, ...
        "o-", "LineWidth", 1.8, "MarkerSize", 6);
    xlabel("Minimum cluster accuracy (%)");
    ylabel("Original units retained (%)");
    title("Unit retention");
    ylim([0 100]);
    grid on

    exportgraphics(figure_handle, figure_file, "Resolution", 200);
    close(figure_handle);
else
    figure_file = "";
end

accuracy_sweep_summary = summary;
save(summary_file, "accuracy_sweep_summary", "result_files", ...
    "input_file", "matrix_file", "model_file", "csv_file", ...
    "figure_file", "total_seconds", "-v7.3");
end
