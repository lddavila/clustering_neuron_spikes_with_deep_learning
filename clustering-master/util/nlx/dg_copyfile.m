function dg_copyfile(the_src, the_dest)
%dg_copyfile(src, dest)
% This is a replacement for Matlab's 'copyfile', which can do bad things on
% a Mac.

%$Rev: 139 $
%$Date: 2012-01-06 22:58:43 -0500 (Fri, 06 Jan 2012) $
%$Author: dgibson $

if ispc
    system(sprintf('copy "%s" "%s"', the_src, the_dest));
elseif ismac || isunix
    system(sprintf('cp "%s" "%s"', the_src, the_dest));
else
    error('dg_copyfile:arch', ...
        'Unrecognized computer platform');
end

