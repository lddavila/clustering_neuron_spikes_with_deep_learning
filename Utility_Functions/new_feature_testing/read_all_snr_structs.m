function [snr_table] = read_all_snr_structs(fp_to_snr_structs,tetrodes_or_channels,plot_or_dont,varargin)
if isempty(varargin)
    all_snr_structs = struct2table(dir(fullfile(fp_to_snr_structs,"*.mat")));
    all_snr_structs.name = string(all_snr_structs.name);
    all_snr_structs.folder = string(all_snr_structs.folder);

    if tetrodes_or_channels=="c"
        channels = str2double(strrep(strrep(all_snr_structs.name,".mat",""),"c",""));
        snrs = zeros(length(channels),1);
        for i=1:height(all_snr_structs)
            the_s = importdata(fullfile(all_snr_structs{i,"folder"},all_snr_structs{i,"name"}));
            snrs(i) = the_s.signal_to_noise_ratio;

            channels = str2double(strrep(strrep(all_snr_structs.name,".mat",""),"c",""));

        end
        snr_table = table(channels,snrs);
        snr_table = sortrows(snr_table,'channels');
    else
        tetrodes = split(all_snr_structs.name,"_");
        %remove the rows which are redundant
        were_misformatted = tetrodes(:,1)=="t";
        all_snr_structs(were_misformatted,:) = [];
        %now get the remaining non misformatted
        tetrodes = split(all_snr_structs.name,"_");


        multipliers = str2double(tetrodes(:,2));
        stages = str2double(strrep(tetrodes(:,4),".mat",""));
        all_snr_structs.tetrode = tetrodes(:,1);
        all_snr_structs.stage = stages;
        all_snr_structs.multiplier = multipliers;
        grouped_data = slice_table_for_parallel_processing(all_snr_structs,["tetrode"]);
        all_rows = [];
        parfor i=1:length(grouped_data)
            current_group = grouped_data{i};

            sub_group = slice_table_for_parallel_processing(current_group,"multiplier");
            for j=1:length(sub_group)
                current_sub_group = sortrows(sub_group{j},"stage");
                snrs = [];
                for k=1:height(current_sub_group)
                    current_snr_struct = importdata(fullfile(current_sub_group{k,"folder"},current_sub_group{k,"name"}));
                    
                    current_raw_signal = sum(current_snr_struct.unit_detection_raw_num);
                    num_spikes = current_snr_struct.num_spikes;
                    current_snr = (current_raw_signal / num_spikes) * 100;
                    var_names = ["stage_"+string(current_sub_group{k,"stage"})+"_snr","raw_signal_"+string(current_sub_group{k,"stage"}),"num_spikes_"+string(current_sub_group{k,"stage"})];
                    snrs = [snrs,table(current_snr,current_raw_signal,num_spikes,'VariableNames',var_names)];
                end

                new_row = table(current_sub_group{1,"tetrode"},current_sub_group{1,"multiplier"},'VariableNames',["tetrode","multiplier"]);
                new_row = [new_row,snrs];
                try
                    all_rows = [all_rows;new_row];
                catch
                end
            end
        end
        snr_table = all_rows;
    end
else
    snr_table = varargin{1};
end

if plot_or_dont
    var_names = string(snr_table.Properties.VariableNames);
    only_stage_names = var_names(contains(var_names,"stage_"));
    only_raw_names = var_names(contains(var_names,"raw"));
    only_num_spikes = var_names(contains(var_names,"num_spikes"));
    all_stages = 1:length(only_stage_names);
    
    grouped_table = slice_table_for_parallel_processing(snr_table,"tetrode");
    for i=1:length(grouped_table)
        current_table = grouped_table{i};
        f = figure;
        tiledlayout('flow')
        nexttile();
        for j=1:height(current_table)
            x_data = all_stages;
            y_data = current_table{j,[only_stage_names]};
            plot(x_data,y_data,'DisplayName',"multiplier "+string(current_table{j,"multiplier"}));
            hold on;
        end
        legend;
        % title("Tetrode "+string(current_table{i,"tetrode"}));
        % xlabel("Stage")
        ylabel("SNR")
        
        nexttile();
        for j=1:height(current_table)
            x_data = all_stages;
            y_data = current_table{j,[only_num_spikes]};
            plot(x_data,y_data,'DisplayName',"multiplier "+string(current_table{j,"multiplier"}));
            hold on;
        end
        legend;
        
        % xlabel("Stage")
        ylabel("data set size")

        nexttile();
        for j=1:height(current_table)
            x_data = all_stages;
            y_data = current_table{j,[only_raw_names]};
            plot(x_data,y_data,'DisplayName',"multiplier "+string(current_table{j,"multiplier"}));
            hold on;
        end
        legend;
        
        % xlabel("Stage")
        ylabel("signal count")
        close(f);

        sgtitle("Tetrode "+string(current_table{i,"tetrode"}));
    end
end

end