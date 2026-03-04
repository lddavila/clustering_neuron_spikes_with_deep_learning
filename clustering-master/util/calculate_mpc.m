%edited by Luis David Davila and Alexander Friedman
function the_mpc = calculate_mpc(the_U)
%CALCULATE_MPC Calculates the Modified Partition Coefficient (MPC) of the
%fuzzy partition matrix
    [c, n] = size(the_U);
    pc = sum(sum(the_U .^ 2)) / n;
    the_mpc = 1 - c/(c-1) * (1 - pc);
end