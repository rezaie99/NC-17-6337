function [ h, abort] = imcreateMM(imsize, binFileName, datatype, fillValue)
%imcreateMM Creates a binary file and returns the handle to the memory
%   mapped file.
%   
%   Creates a memory maped file with a matrix of size "imsize". 
%  
% Usage:
%   h = imcreateMM([100 100 1000],'filename.bin');
%
% Input arguments:
% - imsize          Size of the matrix that will be created
% - binFileName     Name of binary file. If no name is provided a random
%                   name will be created. 
% - fillValue       The value that will be used to fill the matrix and
%                   memory mapped file. Omitting this parameter will have a
%                   significant increase in speed. 
%
% Output arguments:
% - h               handle to the memory mapped file. h.Data.I will get you
%                   the image.
%
% written by Amin Allalou aallalou@mit.edu
%

abort=0;
writable=true; 
if(~exist('binFileName','var'))
    binFileName = ['temp_',num2str(10000*rand(1,1)),'.bin'];
else
    binFileName = [binFileName];
end

if(~exist('fillValue','var'))
    fillValue = -1;
end

if(~exist('datatype','var'))
    datatype = 'uint16';
end

nrDim = numel(imsize);

%Offset 'BINMM', int32 (offset), int32 (nrDim), int32 (datatype)
offset = 5+4+4+4+4*nrDim;

if(exist(binFileName,'file'))
    result = input('File exist, do you want to overwrite? (y/n) ','s');
    if ~strcmpi(result,'y')
        h=0;
        abort=1;
        fprintf('\nExiting\n');
        return;
    end
    delete(binFileName);
end

TotalImageSize = imsize(1);
for i=2:nrDim
    TotalImageSize = TotalImageSize*imsize(i);
end

if fillValue==-1
    filesize  = TotalImageSize*BINMM.sizeOf(datatype)+offset;
    disp(['File of size: ',num2str(filesize)]);
    createBlankFile(binFileName,filesize);
    fid = fopen(binFileName,'r+','ieee-le');
    frewind(fid);
else
    fid = fopen(binFileName,'w','ieee-le');
    
end




%Magic file label
fwrite(fid,'BINMM','*char');

%Write header size
fwrite(fid,offset,'int32');

%Write the datatype
fwrite(fid,BINMM.getDataTypeInt(datatype),'int32');

%Write the dimension of the data
fwrite(fid,nrDim,'int32');
for i=1:nrDim
    fwrite(fid,imsize(i),'int32');
end
% fseek(fid,offset,-1);
icount =0;
if fillValue~=-1
    data=ones(1,imsize(2)*imsize(1))*fillValue;
    
    for i=1:(TotalImageSize/(imsize(1)*imsize(2)))
        
            fwrite(fid,cast(data(:),datatype),datatype);
            icount=icount+1;
    end
end
fclose(fid);
 
%Memory map the file
%h = memmapfile(binFileName,'offset',offset, 'Format', {datatype, imsize, 'I'},'Writable', writable);
h=0;

end

 

 

