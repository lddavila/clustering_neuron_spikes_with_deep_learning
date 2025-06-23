function str = dg_thing2str(thing)
%Creates some kind of a string representation of <thing> come hell or high
%water.

%$Rev: 25 $
%$Date: 2009-03-31 21:56:57 -0400 (Tue, 31 Mar 2009) $
%$Author: dgibson $

switch(class(thing))
    case {'double' 'char'}
        if length(size(thing)) < 3
            if numel(thing) < 100
                str = mat2str(thing);
            else
                str = sprintf('{%dx%d %s}', size(thing,1), size(thing, 2), class(thing));
            end
        else
            str = sprintf('{multi-D %s}', class(thing));
        end
    case 'cell'
        if length(size(thing)) > 2
            str = sprintf('{multi-D %s}', class(thing));
        elseif numel(thing) ~= length(thing)
            str = sprintf('{%dx%d %s}', size(thing,1), size(thing, 2), class(thing));
        else
            if numel(thing) < 100
                str = '{';
                for k=1:length(thing)
                    str = [ str ' ' dg_thing2str(thing{k}) ];
                end
                str = [ str ' }'];
            else
                str = sprintf('{%dx%d %s}', size(thing,1), size(thing, 2), class(thing));
            end
        end
    otherwise
        if length(size(thing)) < 3
            str = sprintf('{%dx%d %s}', size(thing,1), size(thing, 2), class(thing));
        else
            str = sprintf('{multi-D %s}', class(thing));
        end
end
