function StopRecording(~,~)
disp('StopRecording was called')
% StopFcn for timer object
% Yuelong 2013-11
% Ambroise 2014-06

global captime;
global whiteLightLog;
global Temperature;
global tempPath;
global tmpath;
global guivar;
global shockTime;
global PimpshockTime;
global whitePath;
global framesFile;
global frmNb;
fclose(framesFile);

save(tmpath,'captime');
save(tempPath,'Temperature');
save(whitePath,'whiteLightLog');

figure
time = captime(3:end);
[a,b]=max(time - time(1));
plot(time - time(1))
hold on
plot([0 length(time)],[0 guivar.TimeLength],'r');
L{1}='Obtained';
L{2}='What it should be';
n=3;

if ~isempty(shockTime)
    save([tmpath '_shocks.mat'],'shockTime');
    z=zeros(1,length(time));
    z(shockTime)=max(time)*ones(1,length(shockTime));
    plot(z,'g');
    L{n}='Shocks';
    n=n+1;
end

if ~isempty(PimpshockTime)
    save([tmpath '_PimpshockTime.mat'],'PimpshockTime');
    z=zeros(1,length(time));
    z(PimpshockTime)=max(time)*ones(1,length(PimpshockTime));
    plot(z,'y');
    L{n}='PimpShocks';
end

xlabel('Frames #')
ylabel('Time [s]')
legend(L,'Location','NorthWest')
t=diff(captime(3:end)-captime(3));
x=max(t);
title(['Acquired at ' num2str(b/a) ' fps, Largest interval was ' num2str(round(x*1000)) 'ms, ' num2str(length(find(time==0))) ' missing frames']);

frmNb=0;
end