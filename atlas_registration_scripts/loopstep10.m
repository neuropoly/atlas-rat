list = sct_tools_ls('*',0,0,1)
for ii=4:length(list)
    cd(list{ii})

%% run
    step10_extraction_of_metrics

    cd ..
end