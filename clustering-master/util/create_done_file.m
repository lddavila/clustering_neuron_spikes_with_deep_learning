%edited by Luis David Davila and Alexander Friedman
function create_done_file(the_done_filename, the_msg)
    if nargin < 2
        the_msg = '';
    end
    try
        f = fopen(the_done_filename, 'w');
        fwrite(f, the_msg);
        fclose(f);
    catch e
        disp(e.message)
    end
end