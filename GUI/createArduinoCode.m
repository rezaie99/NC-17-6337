function createArduinoCode(bin, differentIntervals, whichInterval, interval)

% <datatype> array [DIM_0_SIZE] [DIM_1_SIZE] = {
%    //as many vals as dim1
%   {val,val,val},
%   {val,val,val}//as many rows as dim0
% };

if ispc
    fid = fopen('..\Arduino Program\shockControlToUpload\shockControlToUpload.ino','wt');
else
    fid = fopen('../Arduino Program/shockControlToUpload/shockControlToUpload.ino','wt');  % Note the 'wt' for writing in text mode
end
a=['const byte index[' num2str(size(bin,1)) '] = {'];
fprintf(fid,'%s\n',a);
a=[];
for i=1:1:size(bin,1)
    %a=[a 'B' bin(i,:) ','];
    a=[a num2str(bin(i)) ','];
end
a(end)=[];
a=[a '};'];
fprintf(fid,'%s\n',a);
a=' ';
fprintf(fid,'%s\n',a);



a=['const int differentIntervals[' num2str(size(differentIntervals,1)) '] = {'];
fprintf(fid,'%s\n',a);
a=[];
for i=1:1:size(differentIntervals,1)
    a=[a num2str(differentIntervals(i)) ','];
end
a(end)=[];
a=[a '};'];
fprintf(fid,'%s\n',a);
a=' ';
fprintf(fid,'%s\n',a);


a=['const int nbOfIntervals = ' num2str(size(whichInterval,1)) ';'];
fprintf(fid,'%s\n',a);
a=' ';
fprintf(fid,'%s\n',a);

a=['const byte whichInterval[' num2str(size(whichInterval,1)) '] = {'];
fprintf(fid,'%s\n',a);
a=[];
for i=1:1:size(whichInterval,1)
    %a=[a 'B' whichInterval(i,:) ','];
    a=[a num2str(whichInterval(i)) ','];
end
a(end)=[];
a=[a '};'];
fprintf(fid,'%s\n',a);
a=' ';
fprintf(fid,'%s\n',a);

a=['const unsigned long interval = ' num2str(interval) ';'];
fprintf(fid,'%s\n',a);
a=' ';
fprintf(fid,'%s\n',a);
if ispc
    code = fileread('..\Arduino Program\shockControl\shockControl.ino');
else
    code = fileread('../Arduino Program/shockControl/shockControl.ino');
end
for i=1:1:size(code,2)
    fprintf(fid,'%s',code(i));
end
fclose(fid);


pause(0.5);

if ispc
    winopen('..\Arduino Program\shockControlToUpload\shockControlToUpload.ino');
else
    macopen('../Arduino Program/shockControlToUpload/shockControlToUpload.ino');
end

end
