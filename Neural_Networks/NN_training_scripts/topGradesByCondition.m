function [topTable, results] = topGradesByCondition(T, rank, outDir)
%TOPGRADESBYCONDITION Top-scoring grade sets for each (level, threshold) pair.
%   Saves each bar graph as a PNG and the summary table as a .mat file
%   in outDir (default: the SpikeSorting_Project folder).

    arguments
        T table
        rank (1,1) {mustBeInteger, mustBePositive}
        outDir (1,1) string = "/Users/justin/Downloads/SpikeSorting_Project"
    end

    if ~isfolder(outDir)
        mkdir(outDir);
    end

    required = ["grades", "level", "threshold", "score", "blacklisted"];
    missing = setdiff(required, string(T.Properties.VariableNames));
    if ~isempty(missing)
        error("topGradesByCondition:missingColumns", ...
              "Table is missing column(s): %s", strjoin(missing, ", "));
    end

    grades = T.grades;
    if ~iscell(grades)
        grades = num2cell(grades, 2);
    end
    levels = T.level;
    thresholds = T.threshold;
    scores = T.score;

    %Unique (level, threshold) ordered pairs
    [conditions, ~, condIdx] = unique([levels, thresholds], "rows");
    nConditions = size(conditions, 1);

    results = struct("level", cell(nConditions, 1), "threshold", [], ...
                     "grades", [], "scores", [], "ranks", []);

    %Rows for the summary table, one cell per condition
    tableParts = cell(nConditions, 1);

    for c = 1:nConditions
        rows = find(condIdx == c);
        [sortedScores, order] = sort(scores(rows), "descend");

        %Tied scores share the best rank in the tie
        %every set ranked within the limit is kept even if it crosses the
        %limit
        ranks = arrayfun(@(s) find(sortedScores == s, 1), sortedScores);
        inTop = ranks <= rank;
        ranks = ranks(inTop);
        n = numel(ranks);
        topRows = rows(order(inTop));

        results(c).level = conditions(c, 1);
        results(c).threshold = conditions(c, 2);
        results(c).grades = grades(topRows);
        results(c).scores = sortedScores(inTop);
        results(c).ranks = ranks;

        labels = cellfun(@mat2str, results(c).grades, "UniformOutput", false);
        tableParts{c} = table( ...
            repmat(results(c).level, n, 1), ...
            repmat(results(c).threshold, n, 1), ...
            ranks, string(labels), results(c).scores, ...
            'VariableNames', ["Level", "Threshold", "Rank", "Grades", "Score"]);

        %Bar graph of the top n scores for this condition
        fig = figure("Name", sprintf("Level %d, Threshold %d", ...
                                     results(c).level, results(c).threshold));
        bar(categorical(1:n), results(c).scores);
        ylim([0,1]);
        xticklabels(compose("#%d %s", ranks, string(labels)));
        xtickangle(45);
        xlabel("Grades");
        ylabel("Score");
        title(sprintf("Top %d scores — Level %d, Threshold %d", ...
                      rank, results(c).level, results(c).threshold));
        grid on;

        exportgraphics(fig, fullfile(outDir, sprintf( ...
            "topGrades_level%d_threshold%d.png", ...
            results(c).level, results(c).threshold)));
    end

    %Summary table of the top grades for every condition
    topTable = vertcat(tableParts{:});
    disp(topTable);
    save(fullfile(outDir, "topGradesTable.mat"), "topTable");
end

%upload figures
%run_entire_sorting_algorithm_ver_2
%detect_spikes_ver_2
