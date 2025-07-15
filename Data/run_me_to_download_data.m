function [] = run_me_to_download_data(api_key,doi,config,use_real)



if ~use_real
    demo_or_real = "https://demo.dataverse.org";
else
    demo_or_real ="https://dataverse.harvard.edu";
end

%get list of all files in the dataset
get_command = "curl -X GET " + ...
    '"' + char(demo_or_real) + "/api/datasets/:persistentId?persistentId=doi:" + char(doi) + '"';

[output, status] = system(get_command, "-echo");

command_to_run = sprintf('curl -L -O -J -H "X-Dataverse-key:%s" "%s/api/access/dataset/:persistentId/?persistentId=doi:%s"', char(api_key), char(demo_or_real), char(doi));

disp("Downloading dataset to "+fullfile(config.base_file_path,"Data",config.RECORDING_NAME));
disp("This Could Take a Moment ...")

file_to_save_to = create_a_file_if_it_doesnt_exist_and_ret_abs_path(fullfile(config.base_file_path,"Data",config.RECORDING_NAME));

[output, something] = system(command_to_run,"-echo");
if ~contains(output,'ok')
    disp("Couldn't download the data. Please ensure your doi and api key are valid");
    display(output);
    display(something);
    return
end

disp("Finished Download, now unzipping")
command_to_run = ['powershell -Command "Expand-Archive -Path \"',char(pwd),'\dataverse_files.zip\" -DestinationPath \"',file_to_save_to,'\""'];
system(command_to_run)
delete(fullfile(pwd,"dataverse_files.zip"));
disp("Finished Restoring, your files are ready to view")

end