function acquisitionEnd(~,~)
disp('acquisitionEnd was called')
global AVT;
% global guivar;
global temperatureTimer;
global isTemperature;
global isPreview;
global hmsg;
% global resultsDir;


%stop camera
stop(AVT.Obj);

%set priority to normal
% Priority(0);


if ishandle(hmsg)
    close(hmsg);
end
hmsg=msgbox('Acquisition is finished !');

if isTemperature
    start(temperatureTimer);
end

if isPreview==0
    startprev();    
end



end