function [alert_list,change_in_accuracy] = compare_previous_stage_to_new_stage(previous_stage,next_stage)
unit_list_from_previous_stage = unique(previous_stage{:,"Unit"});
unit_list_from_next_stage = unique(next_stage{:,"Unit"});

if any(unit_list_from_next_stage ~= unit_list_from_previous_stage)
    error("Missing Units From Stage previous state to next stage.");
end
alert_list = [];

for i=1:size(previous_stage,1)
    if previous_stage{i,"Average Accuracy"} > next_stage{i,"Average Accuracy"}
        alert_list = [alert_list;sprintf("Unit %i's average accuracy decreased",previous_stage{i,"Unit"})];
    end
    if previous_stage{i,"Max Accuracy"} > next_stage{i,"Max Accuracy"}
        alert_list = [alert_list; sprintf("Unit %i's max accuracy was lost", previous_stage{i,"Unit"})];
    end
    if next_stage{i,"Max Accuracy"} <40
        alert_list = [alert_list;sprintf("Unit %i's max possible accuracy has reached 40%",next_stage{i,"Max Accuracy"})];
    end
    if next_stage{i,"# of Appearences"}==0
        alert_list = [alert_list;sprintf("Unit %i has no appearences.",next_stage{i,"Unit"})];
    end

end

change_in_accuracy = table(next_stage{:,"Average Accuracy"}- previous_stage{:,"Average Accuracy"},'VariableNames',["Average Accuracy Change"]);
end