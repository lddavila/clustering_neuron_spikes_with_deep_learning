function create_done_file(done_filename, msg)
    if nargin < 2
        msg = '';
    end
    try
        f = fopen(done_filename, 'w');
        fwrite(f, msg);
        fclose(f);
    catch e
        disp(e.message)
    end
end