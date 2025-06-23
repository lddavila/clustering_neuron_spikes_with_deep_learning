function run_kkconvert(filename, output_directory)
    f = fopen(filename);
    g = textscan(f,'%s','delimiter','\n');
    fclose(f);
    ntt_files = sort(g{1});
    
    for k = 1:length(ntt_files)
        output_filename = fullfile(output_directory, sprintf('tt%03d.fet.0', k));
        convert_to_klustakwik(ntt_files{k}, output_filename);
    end
    disp('Done!')
end

