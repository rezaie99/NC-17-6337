function  h = imloadMM( filename ,writable)
%imloadMM Loads the a binary file as a memory mapped file and returns the
%   handle to the memory mapped file. 
%   
%   Loads the binary file "filename" as a memory mapped file.     
%
% Usage:
%   h = imreadloadMM('imagefile.tif');
%
% Input arguments:
% - filename        the name of the binary file
% - writable        boolean for making the memory mapped file writable
%                   default = true
%
% Output arguments:
% - h               handle to the memory mapped file. h.Data.I will get you
%                   the image.
%
% written by Amin Allalou aallalou@mit.edu
%

if(~exist('writable','var'))
    writable=true; 
end

 
[hOffset imsize datatype] = getBinaryHeader(filename);

%Memory map the file
h = memmapfile(filename,'offset',hOffset, 'Format', {datatype, imsize, 'I'},'Writable', writable);

end

