function [file, b] = quickConvert2mj2()
[file, b, ~] =uigetfile('*.bin', 'MultiSelect', 'on');
if isequal(class(file),'cell')
    nb=size(file,2);
else
    nb=1;
end
for i=1:1:nb
    if isequal(class(file),'cell')
        a=file{i};
    else
        a=file;
    end
    if isequal(a(end-2:end),'bin')
        disp(['start compressing :' a]);
        outputName = [b a(1:end-4) '.mj2'];
        if exist(outputName)>0
            outputName = [b a(1:end-4) ' conflicted file.mj2'];
        end
        vidIn = VideoDataReader([b a]);
        NumberOfFrames = vidIn.imsize(3);
        vidOut = VideoWriter(outputName, 'Archival');
        vidOut.FrameRate=30;
        open(vidOut);
        for n=1:1:NumberOfFrames
            if mod(n,100)==0
                disp([num2str(n) '/' num2str(NumberOfFrames) ' frames compressed']);
            end
            im=Read(vidIn,n);
            writeVideo(vidOut,uint8(im));
        end
        close(vidOut);
    end
end
end