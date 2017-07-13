function createBlankFile(name, sizeFile)
% Create the file
fh = javaObject('java.io.RandomAccessFile', name, 'rw');
% Allocate the right amount of space
fh.setLength(sizeFile);
% Close the file
fh.close();
end