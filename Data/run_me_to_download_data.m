function [] = run_me_to_download_data(doi,config,use_real,recording_name)



if ~use_real
    demo_or_real = "https://demo.dataverse.org";
else
    demo_or_real ="https://dataverse.harvard.edu";
end

%get list of all files in the dataset
get_command = "curl -sL -X GET " + ...
    '"' + char(demo_or_real) + "/api/datasets/:persistentId?persistentId=doi:" + char(doi) + '"';

[~, output] = system(get_command);

disp(output);
decoded_json = jsondecode(output);

file_table = struct2table(decoded_json.data.latestVersion.files);

%create the directories as they are needed
unique_directory_names = unique(string(file_table{:,"directoryLabel"}));
unique_directory_names = split(unique_directory_names,recording_name);
unique_directory_names = unique_directory_names(:,end);
unique_directory_names = strrep(unique_directory_names,"/","");
unique_directory_names = strrep(unique_directory_names,"\","");
for i=1:size(unique_directory_names,1)
    create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Data",recording_name,unique_directory_names(i)));
end


for i=1:size(file_table,1)
    file_name = file_table{i,"label"}{1};
    file_id = file_table{i,"dataFile"}.id;
    directory_label = file_table{i,"directoryLabel"};
    fixed_dir_label = strrep(directory_label,"data/"+recording_name+"/","");
    dir_to_save_to = fullfile(config.base_file_path,"Data",recording_name,fixed_dir_label);
    % Download each file
    url = sprintf('https://dataverse.harvard.edu/api/access/datafile/%d', file_id);
    download_command = sprintf('curl -L -o  "%s" "%s"',fullfile(dir_to_save_to,file_name),url);
    fprintf("Downloading %s ...\n",file_name);
    system(download_command);
end
end