function mpc = calculate_mpc(U)
%CALCULATE_MPC Calculates the Modified Partition Coefficient (MPC) of the
%fuzzy partition matrix
    [c, n] = size(U);
    pc = sum(sum(U .^ 2)) / n;
    mpc = 1 - c/(c-1) * (1 - pc);
end