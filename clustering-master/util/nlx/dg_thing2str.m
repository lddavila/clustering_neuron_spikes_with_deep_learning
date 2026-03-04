%edited by Luis David Davila and Alexander Friedman
function the_str = dg_thing2str(the_cthing)
%Creates some kind of a string representation of <thing> come hell or high
%water.

%$Rev: 25 $
%$Date: 2009-03-31 21:56:57 -0400 (Tue, 31 Mar 2009) $
%$Author: dgibson $

switch(class(the_thing))
    case {'double' 'char'}
        if length(size(the_thing)) < 3
            if numel(the_thing) < 100
                the_str = mat2str(the_thing);
            else
                the_str = sprintf('{%dx%d %s}', size(the_thing,1), size(the_thing, 2), class(the_thing));
            end
        else
            the_str = sprintf('{multi-D %s}', class(the_thing));
        end
    case 'cell'
        if length(size(the_thing)) > 2
            the_str = sprintf('{multi-D %s}', class(the_thing));
        elseif numel(the_thing) ~= length(the_thing)
            the_str = sprintf('{%dx%d %s}', size(the_thing,1), size(the_thing, 2), class(the_thing));
        else
            if numel(the_thing) < 100
                the_str = '{';
                for k=1:length(the_thing)
                    the_str = [ the_str ' ' dg_thing2str(the_thing{k}) ];
                end
                the_str = [ the_str ' }'];
            else
                the_str = sprintf('{%dx%d %s}', size(the_thing,1), size(the_thing, 2), class(the_thing));
            end
        end
    otherwise
        if length(size(the_thing)) < 3
            the_str = sprintf('{%dx%d %s}', size(the_thing,1), size(the_thing, 2), class(the_thing));
        else
            the_str = sprintf('{multi-D %s}', class(the_thing));
        end
end
