function T=compressionSpeedTest(nbFrames)

try
    delete('speedtest.mj2');
end
try
    delete('speedtest.avi');
end
try
    delete('speedtest.bin');
end
try
    delete('speedtest.mp4');
end
clc


global AVT;
try
    start(AVT.Obj);
catch
end


% H=1000;
% W=H;
% nbFrames = 100;
%
% im = rand(H)*255;
% im = uint8(im);
im=getsnapshot(AVT.Obj);
im = uint8(im);

H=size(im,1);
W=size(im,2);

T = zeros(7,nbFrames);



'Archival'
vidObj = VideoWriter('speedtest.mj2','Archival');
open(vidObj);
for i=1:1:nbFrames
    pause(0.002);tic
    writeVideo(vidObj,getsnapshot(AVT.Obj));
    T(1,i)= toc;
end
close(vidObj);
delete('speedtest.mj2');
save('resultspeedtest1.mat','T')


'Motion JPEG AVI'
vidObj = VideoWriter('speedtest.avi','Motion JPEG AVI');
open(vidObj);
for i=1:1:nbFrames
    pause(0.002);tic
    writeVideo(vidObj,getsnapshot(AVT.Obj));
    T(2,i)= toc;
end
close(vidObj);
delete('speedtest.avi');

save('resultspeedtest2.mat','T')


'Uncompressed AVI'
vidObj = VideoWriter('speedtest.avi','Uncompressed AVI');
open(vidObj);
for i=1:1:nbFrames
    pause(0.002);tic
    writeVideo(vidObj,getsnapshot(AVT.Obj));
    T(3,i)= toc;
end
close(vidObj);

delete('speedtest.avi');

save('resultspeedtest3.mat','T')


'Motion JPEG 2000'
vidObj = VideoWriter('speedtest.mj2','Motion JPEG 2000');
open(vidObj);
for i=1:1:nbFrames
    pause(0.002);tic
    writeVideo(vidObj,getsnapshot(AVT.Obj));
    T(4,i)= toc;
end
close(vidObj);
delete('speedtest.mj2');

save('resultspeedtest4.mat','T')



'MPEG-4'
vidObj = VideoWriter('speedtest.mp4','MPEG-4');
open(vidObj);
for i=1:1:nbFrames
    pause(0.002);tic
    writeVideo(vidObj,getsnapshot(AVT.Obj));
    T(5,i)= toc;
end
close(vidObj);
delete('speedtest.mp4');

save('resultspeedtest5.mat','T')



'Grayscale AVI'
vidObj = VideoWriter('speedtest.avi','Grayscale AVI');
open(vidObj);
for i=1:1:nbFrames
    pause(0.002);tic
    writeVideo(vidObj,getsnapshot(AVT.Obj));
    T(6,i)= toc;
end
close(vidObj);
delete('speedtest.avi');

save('resultspeedtest6.mat','T')



[~,abort]=imcreateMM([H,W,nbFrames], 'speedtest.bin', 'uint8');
[hOffset,~,~] = getBinaryHeader('speedtest.bin');
framesFile = fopen('speedtest.bin', 'r+');
fseek(framesFile, hOffset, -1);

for i=1:1:nbFrames
    pause(0.002);tic
    fwrite(framesFile, getsnapshot(AVT.Obj), 'uint8');
    T(7,i)= toc;
end
fclose(framesFile);
delete('speedtest.bin');

save('resultspeedtest7.mat','T')
save('resultspeedtest.mat','T')


close all
for i=1:1:7
    if i==7
        plot(T(i,:),'r')
    else
        plot(T(i,:))
    end
    hold on;
end
% legend('Archival', 'Motion JPEG AVI','Uncompressed AVI','Motion JPEG 2000','MPEG-4','Grayscale AVI', 'Binary File');
figure

bar(mean(T,2));
hold on;
set(gca,'XTickLabel',[]);

e = std(T');
h=errorbar(1:7,mean(T,2),e,'k');
set(h,'linestyle','none');



end
