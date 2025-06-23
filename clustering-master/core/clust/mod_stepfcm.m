function [U_new, center, obj_fcn] = mod_stepfcm(data, U, cluster_n, expo)
%MOD_STEPFCM One step in fuzzy c-mean clustering. Modified for efficiency.
%   [U_NEW, CENTER, ERR] = STEPFCM(DATA, U, CLUSTER_N, EXPO)
%   performs one iteration of fuzzy c-mean clustering, where
%
%   DATA: matrix of data to be clustered. (Each row is a data point.)
%   U: partition matrix. (U(i,j) is the MF value of data j in cluster j.)
%   CLUSTER_N: number of clusters.
%   EXPO: exponent (> 1) for the partition matrix.
%   U_NEW: new partition matrix.
%   CENTER: center of clusters. (Each row is a center.)
%   ERR: objective function for partition U.
%
%   Note that the situation of "singularity" (one of the data points is
%   exactly the same as one of the cluster centers) is not checked.
%   However, it hardly occurs in practice.
%
%       See also DISTFCM, INITFCM, IRISFCM, FCMDEMO, FCM.

%   Roger Jang, 11-22-94.
%   Copyright 1994-2002 The MathWorks, Inc. 
%   $Revision: 1.13 $  $Date: 2002/04/14 22:21:02 $

mf = U.^expo;       % MF matrix after exponential modification
mf_sum = sum(mf, 2);
center = mf*data./mf_sum(:, ones(1, size(data, 2))); % new center
dist = distfcm(center, data);       % fill the distance matrix
obj_fcn = sum(sum((dist.^2).*mf));  % objective function
tmp = 1./(dist .^ (2/(expo-1)));      % calculate new U, suppose expo != 1
U_new = tmp./repmat(sum(tmp), cluster_n, 1);
