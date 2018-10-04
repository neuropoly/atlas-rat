% list Sample folders, discarding the *flip folders

function new_list = list_sample_folders()
    % get names of sample folders
    list_samples = sct_tools_ls('Sample*');
    % remove flip folders
    j=1;
    for i=1:length(list_samples)
        if isempty(findstr(list_samples{i}, 'flip'))
            new_list{j} = list_samples{i};
            j=j+1;
        end
    end
    list_samples = new_list;
