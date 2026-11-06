classdef RunEntireDetectSpikesTest < matlab.unittest.TestCase
    % Checks that run_entire_clustering_algorithm_ver_2 wires up
    % detect_spikes_ver_3 correctly, using the trimmed copy
    % run_entire_clustering_algorithm_ver_2_detect_only on 4 real channels
    % of the 10_100 recording. Results are compared with values computed
    % straight from the raw recording files.
    %
    % Run:  runtests("RunEntireDetectSpikesTest")   (takes a few minutes)

    properties (Constant)
        Channels = ["c1.mat","c2.mat","c97.mat","c98.mat"]
    end

    properties
        Config      % config returned by the pipeline
        InputConfig % config passed in, for reruns
        Thresholds
        Locs
        Vals
    end

    methods (TestClassSetup)
        function runPipelineOnce(testCase)
            project_dir = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(project_dir,"IncludingSubfolders",true));
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(project_dir)); % spikesort_config needs this
            results = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);

            config = spikesort_config();
            config.RECORDING_NAME = "10_100";
            config.DIR_WITH_OG_CHANNEL_RECORDINGS = fullfile(config.base_file_path,"Data","10_100","recordings_by_channel");
            config.BLIND_PASS_DIR_PRECOMPUTED = string(results.Folder);
            % apply_filter currently fails on row-vector recordings
            config.use_bandpass = false;
            testCase.InputConfig = config;

            [testCase.Thresholds, testCase.Locs, testCase.Vals, testCase.Config] = ...
                run_entire_clustering_algorithm_ver_2_detect_only(config,"ordered_list_of_channels",testCase.Channels);
        end
    end

    methods (Test)
        function readsTheOriginalRecordings(testCase)
            testCase.verifyEqual(string(testCase.Config.test_dir_with_channel_recordings), ...
                string(testCase.InputConfig.DIR_WITH_OG_CHANNEL_RECORDINGS));
        end

        function spikesFolderIsNamedAfterLowestZScore(testCase)
            [~, name] = fileparts(testCase.Config.test_spikes_per_channel_dir);
            testCase.verifyEqual(string(name), "spikes_per_channel min_z_score " + ...
                string(min(testCase.Config.DEFAULT_CLUSTERING_Z_SCORES)));
        end

        function returnsOneEntryPerChannel(testCase)
            n = numel(testCase.Channels);
            testCase.verifyNumElements(testCase.Locs, n);
            testCase.verifyNumElements(testCase.Vals, n);
            for i = 1:n
                testCase.verifyNotEmpty(testCase.Locs{i}, testCase.Channels(i) + " has no spikes");
            end
        end

        function zScoreFilesMatchTheScaledRecording(testCase)
            for i = 1:numel(testCase.Channels)
                [~, z_expected] = testCase.reference(i);
                z_saved = importdata(fullfile(testCase.Config.test_z_score_dir, testCase.Channels(i)));
                testCase.verifyEqual(z_saved, z_expected, "AbsTol", single(1e-4), "RelTol", single(1e-5), testCase.Channels(i));
            end
        end

        function everySpikeIsAboveTheThreshold(testCase)
            min_z = min(testCase.Config.DEFAULT_CLUSTERING_Z_SCORES);
            for i = 1:numel(testCase.Channels)
                [~, z] = testCase.reference(i);
                testCase.verifyGreaterThanOrEqual(abs(z(testCase.Locs{i})), min_z, testCase.Channels(i));
            end
        end

        function spikeLocationsMatchReference(testCase)
            for i = 1:numel(testCase.Channels)
                [~, ~, locs] = testCase.reference(i);
                testCase.verifyEqual(testCase.Locs{i}, locs, testCase.Channels(i));
            end
        end

        function amplitudesMatchReference(testCase)
            for i = 1:numel(testCase.Channels)
                [~, ~, ~, vals] = testCase.reference(i);
                testCase.verifyEqual(testCase.Vals{i}, vals, testCase.Channels(i));
            end
        end

        function thresholdsMatchReference(testCase)
            for i = 1:numel(testCase.Channels)
                [~, ~, ~, ~, thresholds] = testCase.reference(i);
                testCase.verifyEqual(testCase.Thresholds{i}, thresholds, testCase.Channels(i));
            end
        end

        function thresholdsAreStoredOnConfig(testCase)
            testCase.verifyEqual(testCase.Config.Multipliers_in_mv, testCase.Thresholds);
        end

        function rerunReturnsSameResults(testCase)
            [th, locs, vals] = run_entire_clustering_algorithm_ver_2_detect_only( ...
                testCase.InputConfig,"ordered_list_of_channels",testCase.Channels);
            testCase.verifyEqual(th, testCase.Thresholds);
            testCase.verifyEqual(locs, testCase.Locs);
            testCase.verifyEqual(vals, testCase.Vals);
        end
    end

    methods
        function [scaled, z, locs, vals, thresholds] = reference(testCase, i)
            % recompute channel i from the raw recording, independent of
            % any files the pipeline wrote
            config = testCase.Config;
            raw = importdata(fullfile(config.DIR_WITH_OG_CHANNEL_RECORDINGS, testCase.Channels(i)));
            scaled = raw * config.SCALE_FACTOR;
            z = zscore(single(raw) * single(config.SCALE_FACTOR));
            min_z = min(config.DEFAULT_CLUSTERING_Z_SCORES);

            kept = scaled;
            kept(abs(z) < min_z) = 0;
            [vals, locs] = findpeaks(kept);
            locs(vals == 0) = [];
            vals(vals == 0) = [];

            thresholds = nan(1, numel(config.DEFAULT_CLUSTERING_Z_SCORES));
            for j = 1:numel(config.DEFAULT_CLUSTERING_Z_SCORES)
                first = find(abs(z) >= config.DEFAULT_CLUSTERING_Z_SCORES(j), 1);
                if ~isempty(first)
                    thresholds(j) = abs(kept(first));
                end
            end
        end
    end
end
