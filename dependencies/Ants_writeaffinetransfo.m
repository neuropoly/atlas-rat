function Ants_writeaffinetransfo(M)
M = [M(1,1) M(1,2) M(2,1) M(2,2) M(1,3) M(2,3)];

%%
fid = fopen('affine_transfo.txt','w');
fprintf(fid,'%s\n','#Insight Transform File V1.0');
fprintf(fid,'%s\n','#Transform 0');
fprintf(fid,'%s\n','Transform: AffineTransform_double_2_2');
fprintf(fid,'%s','Parameters: ');
fprintf(fid,'%5f ',M(:)');
fprintf(fid,'\n%s\n','FixedParameters: -3.8 -3.8');

fclose(fid)

