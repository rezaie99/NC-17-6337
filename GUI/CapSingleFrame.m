function CapSingleFrame(TimerObj,~)
% Capture a single frame, work as TimerFcn for timer object
% Yuelong 2013-11
% Ambroise 2014-06

global AVT;
global captime;
% global isShock;
global frmNb;
global framesFile;


% global resultsDir;

% trigger(AVT.Obj);
% t=toc;
% F=getdata(AVT.Obj);
% toc-t
% tic
% s1=1;
% s2=2;
% s3=3;
% save([resultsDir 'state.mat'],'s1');
% F=getsnapshot(AVT.Obj);
% save([resultsDir 'state.mat'],'s2');
% toc
% fwrite(framesFile, F, 'uint8');
% F=getsnapshot(AVT.Obj);
fwrite(framesFile,getsnapshot(AVT.Obj) , 'uint8');
% save([resultsDir 'state.mat'],'s3');
% fwrite(framesFile, F, 'uint8');

captime(frmNb+2) = toc;

if toc-captime(3)>captime(1)
    stop(TimerObj);
end

% if isShock==1
%     global shocksArduino;
%     if shocksArduino.BytesAvailable>0
%         ss=fscanf(shocksArduino,'%d');
%         R = 250;
%         V=3;
%         U = ss.*5./1023;
%         I = U./R
%         %Rw = (V-U)./I
%     end
% end



frmNb=frmNb+1;


end