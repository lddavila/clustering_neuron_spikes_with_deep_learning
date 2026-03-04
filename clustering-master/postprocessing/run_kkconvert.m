%edited by Luis David Davila and Alexander Friedman
function run_kkconvert(the_filename, the_output_directory)
    f = fopen(the_filename);
    g = textscan(f,'%s','delimiter','\n');
    fclose(f);
    ntt_files = sort(g{1});
    
    for k = 1:length(ntt_files)
        output_filename = fullfile(the_output_directory, sprintf('tt%03d.fet.0', k));
        convert_to_klustakwik(ntt_files{k}, output_filename);
    end
    disp('Done!')
end

