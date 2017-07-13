function TempOnlyStopRecording(TimerObj,~)
disp('StopRecording was called')
% StopFcn for timer object
% Yuelong 2013-11


global captime;
global Temperature;
global tempPath;

global tmpath; 
toc;
save(tmpath,'captime');
save(tempPath,'Temperature');
delete(TimerObj);

global hmsg;
if ishandle(hmsg)
    close(hmsg);
end
hmsg=msgbox('Acquisition is finished !');
global temperatureTimer;
start(temperatureTimer);


end