function [hOffset imsize datatype] = getBinaryHeader(file)
 
fid = fopen(file,'r');
fseek(fid,0,-1);
if strcmp(fread(fid,5,'*char')','DCIMG') %DCIMG file type
    fprintf('FileType: DCIMG\n');

    %position for nr of frames 36
    fseek(fid,36,-1)
    imsize(3) =  (fread(fid,1,'int32'));

    %position of width or height 164 and 172
    fseek(fid,164,-1);
    imsize(1) =  (fread(fid,1,'int32'));
    fseek(fid,172,-1);
    imsize(2) =    (fread(fid,1,'int32'));
 
    %Data seems to be located at, at least as long as the 
    %image size is 2048
    hOffset = 232;
    
    datatype = 'uint16';
    fclose(fid);
    return;
end

fseek(fid,0,-1);
if strcmp(fread(fid,5,'*char')','BINMM') %BINMM file type
    fprintf('FileType: Binary New format\n');
    %Get header offset
    hOffset =  (fread(fid,1,'int32'));

    %Get datatype 
    datatype = BINMM.getDataType(fread(fid,1,'int32'));
    %position of width or height 164 and 172
    nrDim =  (fread(fid,1,'int32'));
    for i=1:nrDim
        imsize(i) = fread(fid,1,'int32');
    end 
    
    fclose(fid);
    return;
end

fseek(fid,0,-1);

fprintf('FileType: .bin (old)\n');
%Read header size
hOffset=fread(fid,1,'int32');

%Read header info
imsize(1)=fread(fid,1,'int32');
imsize(2)=fread(fid,1,'int32');
imsize(3)=fread(fid,1,'int32');

datatype = 'uint16';

fclose(fid);