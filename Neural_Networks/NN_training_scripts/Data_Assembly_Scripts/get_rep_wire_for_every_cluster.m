function [rep_wires,channels] = get_rep_wire_for_every_cluster(blind_pass_table)
rep_wires = blind_pass_table{:,"rep_wire_1"};
channels = blind_pass_table{:,"rep_channel_1"};
end