%this file has been edited by Luis D. Davila and Alexander Friedman
function [the_passed_value, the_good_value,fig_handle] = overlap_test(dim_aka_channel, the_new_config,dimension_number,varargin)
%OVERLAP_TEST Performs the overlap test as part of dimension selection.
%   [passed, good] = OVERLAP_TEST(dim) returns whether the dimension passed
%   the overlap test, as well as whether it can be considered a "good"
%   dimension.
%
%   The idea is to examine valleys and estimate distribution overlap by
%   evaluating the relationship between the valley and the two surrounding
%   peaks.

the_passed_value = false;
the_good_value = false;

% k * width estimation derived from ksdensity, assuming sig = 1 because
% of zscore normalization.
k = the_new_config.params.OT_WIDTH_SCALING_FACTOR;
width = k * (4/(3 * length(dim_aka_channel)))^(1/5);
[f, xi] = ksdensity(dim_aka_channel, 'width', width);

if ~isempty(varargin) && varargin{1}
    fig_handle = figure();
    tiledlayout(2,2);
    nexttile();
    plot(xi,f,'DisplayName',"TRUE: ksdensity estimation: k"+string(k)+" width: "+string(width));
    hold on;
    possible_k = 0.01:.05:.99;
    legend;
    for i=1:length(possible_k)
        local_width = possible_k(i) * (4/(3 * length(dim_aka_channel)))^(1/5);
        [local_f,local_xi] = ksdensity(dim_aka_channel,'width',possible_k(i));
        plot(local_xi,local_f,'DisplayName',"alternate OT\_WIDTH\_SCALING\_FACTOR: "+string(possible_k(i))+" width: "+string(local_width));
    end
    hold on;
    xlabel("Estimated Function Values");
    ylabel("Evalutation Points");
    title_string = ["Dimension: "+string(dimension_number)+ " OT_WIDTH_SCALING_FACTOR: "+string(k)];
    title_string = [title_string+" OT_EPSILON:"+sprintf("%.2f",the_new_config.params.OT_EPSILON)];
    title_string = [title_string+" OT_PEAK_RADIUS:"+sprintf("%.2f",the_new_config.params.OT_PEAK_RADIUS)];
    title_string = [title_string+" OT_HIGH_VALLEY_THRESH:"+sprintf("%.2f",the_new_config.params.OT_HIGH_VALLEY_THRESH)];
    sgtitle(strrep(title_string,"_","\_"));
    legend
    nexttile();
    title("First Seperable Test");
end

pks = find_peaks(f);
if isempty(pks)
    disp("No Peaks Found for dim" + string(dimension_number))
end
valleys = find_peaks(-1 * f);
if isempty(valleys)
    disp("No valleys found for dim" + string(dimension_number))
end
pks = pks{1};
valleys = valleys{1};


if ~isempty(varargin) && varargin{1}

end


if ~isempty(pks) && length(dim_aka_channel) > the_new_config.params.OT_MIN_SPIKES_LARGE_CLUSTER
    [p, ind] = max(f(pks));
    pkind = pks(ind);
    vals = abs(diff(f)) < the_new_config.params.OT_EPSILON;
    start = max(pkind - the_new_config.params.OT_PEAK_RADIUS, 1);
    fin   = min(pkind + the_new_config.params.OT_PEAK_RADIUS, length(vals));
    vals(start:fin) = false;

    if ~isempty(varargin) && varargin{1}
        
        yline(the_new_config.params.OT_HIGH_VALLEY_THRESH,'DisplayName','OT\_HIGH\_VALLEY\_THRESH');
        hold on;

        possible_starts = 1:1:length(f)-1; %possible starts
        possible_ends = 2:1:length(f); %possible ends

        possible_peak_lengths = (possible_ends - possible_starts.');
        possible_peak_lengths = unique(possible_peak_lengths(possible_peak_lengths>1));
        possible_peak_lengths(isnan(possible_peak_lengths)) = []; % all possible lengths

        x3_inputs = 0.0001:0.001:0.002; %possible OT Episilon



        % will_pass_function = 

        legend
    end
    if any(f(vals) ./ p > the_new_config.params.OT_HIGH_VALLEY_THRESH) %how many values that aren't part of the peak divided by the peak value are greater than OT_HIGH_VALLEY_THRESH
        the_passed_value = true;
        return
    end
end

for valley = valleys'
    pk_before = find(pks < valley);
    pk_after = find(pks > valley);



    if ~isempty(pk_before) && ~isempty(pk_after)
        if ~isempty(varargin) && varargin{1}
            before = scatter(xi(pks(pk_before)),f(pks(pk_before)),'filled','DisplayName','Peak Before');
            after = scatter(xi(pks(pk_after)),f(pks(pk_after)),'filled','DisplayName','Peak After');
            legend;
        end
        val = f(valley);
        if ~isempty(varargin) && varargin{1}
            scatter(xi(valley),f(valley),'filled','DisplayName','Valley');
            legend;
        end
        pkval_before = max(f(pks(pk_before)));
        pkval_after = max(f(pks(pk_after)));
        minpk = min(pkval_before, pkval_after);

        if minpk == pkval_before
            % before.DisplayName = before.DisplayName + " AKA min peak";
            % after.DisplayName = after.DisplayName +" AKA max peak";
            maxpk = pkval_after;
            condition = dim_aka_channel < xi(valley);
            csum = sum(condition);
            leg_val = "Less Than";
            opp_leg_val = "Greater Than";
        else
            % after.DisplayName = after.DisplayName +" AKA min peak";
            % before.DisplayName = before.DisplayName +" AKA max peak";
            maxpk = pkval_before;
            condition =dim_aka_channel > xi(valley) ;
            csum = sum(condition);
            leg_val = "Greater Than";
            opp_leg_val = "Less Than";
        end
        if ~isempty(varargin) && varargin{1}
            % nexttile();
            scatter(double(condition(condition)),dim_aka_channel(condition),'filled','DisplayName',leg_val+" the valley "+string(csum));
            hold on;
            scatter(double(condition(~condition)),dim_aka_channel(~condition),'filled','DisplayName',opp_leg_val +" the valley "+string(length(condition)-csum))

            yline(xi(valley),'Label','Valley','DisplayName',"Valley");
            xline(0.5,'HandleVisibility','off');
            xlim([-2,2]);
            ylim([-1*max(abs(dim_aka_channel))-5,max(abs(dim_aka_channel))+5]);
            legend
        end
        min_size = min(the_new_config.params.OT_MIN_CLUSTER_PERCENT * length(dim_aka_channel), ...
            the_new_config.params.OT_MIN_CLUSTER_SIZE_UPPER_BOUND);
        if ~isempty(varargin) && varargin{1} && valley == valleys(1)
            title_string = [title_string+sprintf(" Min Size: %.2f",min_size)];
            title_string = [title_string+sprintf(" OT_MAX_VALLEY_PERCENT: %.2f",the_new_config.params.OT_MAX_VALLEY_PERCENT)];
            sgtitle(strrep(title_string,"_","\_"));
            legend;
        end
        if ~isempty(varargin) && varargin{1} && valley == valleys(1)
            nexttile;
            x_vals = 0:.1:1;
            y_vals = maxpk * x_vals;
            plot(x_vals,y_vals,'DisplayName','Function of maxpk * possible OT\_MAX\_VALLEY\_PERCENT');
            yline(val)
            hold on;
            scatter(x_vals(find(x_vals==the_new_config.params.OT_MAX_VALLEY_PERCENT)),y_vals(find(x_vals==the_new_config.params.OT_MAX_VALLEY_PERCENT)),'DisplayName','Current OT\_MAX\_VALLEY\_PERCENT')
            legend;
            title("Second Seperable Test")
        end
        if val < the_new_config.params.OT_MAX_VALLEY_PERCENT * maxpk && csum > min_size
            % Significant dip

            the_passed_value = true;
            if val < the_new_config.params.OT_MAX_SIG_VALLEY_PERCENT * maxpk || ...
                    (minpk > the_new_config.params.OT_HEIGHT_THRESH * maxpk && ...
                    val < the_new_config.params.OT_HEIGHT_THRESH * maxpk)
                the_good_value = true;
            end
            return
        end
    end
end

if ~isempty(varargin) && varargin{1}

end
end