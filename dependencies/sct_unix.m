function [status, result] = sct_unix(cmd)
disp(['<strong>' cmd '</strong>']);
[status, result] =unix(['bash -c "' cmd '"']);
if status, disp('ERROR!!!!!!!!!!'); disp(result); end